"""Validate untrusted VSIX metadata without extracting files or executing package code."""

import json
import stat
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import PurePosixPath

NAMESPACE = "http://schemas.microsoft.com/developer/vsx-schema/2011"
METADATA_LIMIT = 1024 * 1024
EXPANSION_LIMIT = 512 * 1024 * 1024


def verify_vsix(filename, version):
    """Require one canonical, bounded package for the intended extension and stable channel."""
    with zipfile.ZipFile(filename) as archive:
        entries = archive.infolist()
        names = [entry.filename for entry in entries]
        if len(entries) > 20000 or len(set(names)) != len(names):
            raise ValueError("Duplicate or excessive VSIX entries")
        if sum(entry.file_size for entry in entries) > EXPANSION_LIMIT:
            raise ValueError("VSIX expansion exceeds the supported bound")
        critical = ["extension/package.json", "extension.vsixmanifest",
                    "extension/client/dist/extension.js", "extension/server/dist/server.js"]
        for entry in entries:
            name = entry.filename
            if entry.orig_filename != name or "\x00" in name:
                raise ValueError("Unsafe VSIX entry name")
            normalized = PurePosixPath(name)
            mode = stat.S_IFMT(entry.external_attr >> 16)
            if normalized.is_absolute() or ".." in normalized.parts or "\\" in name or ":" in name:
                raise ValueError("Unsafe VSIX entry path")
            canonical = str(normalized)
            expected_name = canonical + ("/" if entry.is_dir() else "")
            if expected_name != name or mode not in (0, stat.S_IFREG, stat.S_IFDIR):
                raise ValueError("Non-canonical or special VSIX entry")
            for target in critical:
                if canonical.casefold() == target.casefold() and name != target:
                    raise ValueError("Unsafe VSIX metadata path alias")
        required = critical
        for name in required:
            entry = archive.getinfo(name)
            if entry.is_dir() or stat.S_ISDIR(entry.external_attr >> 16):
                raise ValueError("VSIX metadata and compiled files must be regular files")
        for name in required[:2]:
            if archive.getinfo(name).file_size > METADATA_LIMIT:
                raise ValueError("VSIX metadata exceeds the supported bound")
        manifest = json.loads(archive.read(required[0]).decode("utf-8-sig"))
        xml = archive.read(required[1]).decode("utf-8-sig")
        if "<!DOCTYPE" in xml or "<!ENTITY" in xml:
            raise ValueError("VSIX DTD and entity declarations are unsupported")
        root = ET.fromstring(xml)
        if root.tag != "{" + NAMESPACE + "}PackageManifest":
            raise ValueError("Unexpected VSIX XML root")
        ns = {"v": NAMESPACE}
        if any(not element.tag.startswith("{" + NAMESPACE + "}") for element in root.iter()):
            raise ValueError("Unexpected VSIX XML element namespace")
        metadata = root.findall("v:Metadata", ns)
        identities = root.findall("v:Metadata/v:Identity", ns)
        if len(metadata) != 1 or len(identities) != 1 or len(list(root.iter("{" + NAMESPACE + "}Identity"))) != 1:
            raise ValueError("Expected one unambiguous VSIX XML identity")
        identity = identities[0].attrib
        if set(identity) - {"Id", "Publisher", "Version", "Language", "TargetPlatform"}:
            raise ValueError("Unexpected VSIX XML identity attributes")
        if (manifest.get("name"), manifest.get("publisher"), manifest.get("version")) != ("z-ls", "milkeclair", version):
            raise ValueError("Unexpected VSIX JSON identity")
        if (identity.get("Id"), identity.get("Publisher"), identity.get("Version")) != ("z-ls", "milkeclair", version):
            raise ValueError("Unexpected VSIX XML identity")
        if identity.get("TargetPlatform"):
            raise ValueError("The release workflow expects a universal VSIX")
        for prop in root.findall("v:Metadata/v:Properties/v:Property", ns):
            if set(prop.attrib) - {"Id", "Value"}:
                raise ValueError("Unexpected VSIX XML property attributes")
            if prop.get("Id", "").casefold() == "microsoft.visualstudio.code.prerelease" and prop.get("Value", "").casefold() != "false":
                raise ValueError("The release workflow expects a stable VSIX")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("Usage: verify_vsix.py package.vsix version")
    try:
        verify_vsix(sys.argv[1], sys.argv[2])
    except (ValueError, KeyError, OSError, zipfile.BadZipFile, ET.ParseError) as error:
        raise SystemExit(str(error))
