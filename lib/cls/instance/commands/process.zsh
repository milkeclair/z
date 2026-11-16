# Validate command names before an instance changes the shell.
#
# $@: proposed command names
# REPLY: unchanged
# return: 0 if every name is available or owned, otherwise 1 with an error
z.cls.instance.commands._validate() {
  local REPLY=""
  local z_cls_member

  for z_cls_member in "$@"; do
    if z.var.exists "aliases[$z_cls_member]" || z.var.exists "galiases[$z_cls_member]"; then
      z.io.error "Command $z_cls_member already exists."
      return 1
    fi

    if z.is.not.null "${z_cls_wrapper_refs[$z_cls_member]:-}" &&
        z.cls.instance._owns "$z_cls_member"; then
      continue
    fi

    if z.var.exists "functions[$z_cls_member]" || z.var.exists "commands[$z_cls_member]"; then
      z.io.error "Command $z_cls_member already exists."
      return 1
    fi
  done

  return 0
}

# Install shared dispatch programs and count their instance references.
#
# $@: validated command names
# REPLY: unchanged
# return: 0
z.cls.instance.commands._install() {
  local z_cls_member

  for z_cls_member in "$@"; do
    local z_cls_name=${z_cls_member#*.}
    local z_cls_operation=method

    if z.str.includes "$z_cls_name" .; then
      z_cls_operation=${z_cls_name##*.}
      z_cls_name=${z_cls_name%.*}
    fi

    local z_cls_template="z_cls_dispatch_${z_cls_operation}_$z_cls_name"

    if ! z.var.exists "functions[$z_cls_template]"; then
      functions[$z_cls_template]='z.cls.instance._call "${funcstack[1]%%.*}" '"$z_cls_operation ${(q)z_cls_name}"' "$@"'
      z_cls_dispatch_programs[${z_cls_member#*.}]=$functions[$z_cls_template]
    fi

    functions -c "$z_cls_template" "$z_cls_member"
    unset "z_cls_wrapper_bodies[$z_cls_member]"
    (( z_cls_wrapper_refs[$z_cls_member] += 1 ))
  done

  return 0
}
