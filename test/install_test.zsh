source ${z_main}

z.t.describe "z.install.mod._install_names"; {
  z.t.context "dependencyがすでにinstall済みの場合"; {
    z.t.it "skipせずに最新のdependencyへ更新する"; {
      local install_dir=/tmp/z_t/install_mod/install
      local source_dir=/tmp/z_t/install_mod/source
      local mod_name=wtproxy
      local current_mod_name
      local mod_source_dir
      local mod_target_dir

      rm -rf /tmp/z_t/install_mod
      mkdir -p "$source_dir/mod/git" "$source_dir/mod/wtproxy" "$install_dir/git"
      print -r -- old > "$install_dir/git/version.txt"
      print -r -- new > "$source_dir/mod/git/version.txt"
      print -r -- wtproxy > "$source_dir/mod/wtproxy/version.txt"

      z.install.mod._install_names git wtproxy

      z.t.expect.status.is.true skip_unmock=true
      local git_content=$(cat "$install_dir/git/version.txt")
      local wtproxy_content=$(cat "$install_dir/wtproxy/version.txt")
      z.t.expect "$git_content" new skip_unmock=true
      z.t.expect "$wtproxy_content" wtproxy

      rm -rf /tmp/z_t/install_mod
      unset install_dir source_dir mod_name current_mod_name mod_source_dir mod_target_dir git_content wtproxy_content
    }
  }
}
