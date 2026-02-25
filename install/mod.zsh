z.install.mod._validate_name() {
  if [[ -z $mod_name ]]; then
    echo "❌ mod name is required"
    echo "   usage: z.install.mod <mod_name>"
    return 1
  fi
}

z.install.mod._validate_z_root() {
  if [[ -z $Z_ROOT ]]; then
    echo "❌ Z_ROOT is not set"
    echo "   source main.zsh first"
    return 1
  fi
}

z.install.mod._start() {
  echo "📦 installing mod..."
  echo "     name: $mod_name"
  echo "     github: https://github.com/$github_repo"
  echo "     branch: $github_branch"
  echo "     install dir: $install_dir"
  echo ""
}

z.install.mod._question_overwrite_mod_dir() {
  if [[ ! -d $mod_target_dir ]]; then
    return 0
  fi

  echo "⚠️ mod already exists: $mod_target_dir"
  echo -n "overwrite? (y/n): "
  read -r response
  if [[ ! $response =~ ^[yY]$ ]]; then
    echo "❌ canceled"
    return 1
  fi
  echo ""
}

z.install.mod._remove_existing_mod_dir() {
  if [[ ! -d $mod_target_dir ]]; then
    return 0
  fi

  if ! rm -rf "$mod_target_dir"; then
    echo "❌ failed to remove: $mod_target_dir"
    return 1
  fi
}

z.install.mod._copy_mod_files() {
  if ! mkdir -p $install_dir; then
    echo "❌ failed to create mod dir: $install_dir"
    return 1
  fi

  if ! cp -r "$mod_source_dir" "$install_dir/"; then
    echo "❌ failed to copy mod: $mod_name"
    return 1
  fi
}

z.install.mod._show_completion() {
  echo ""
  echo "✅ mod installation completed: $mod_name"
}

# install z modifier
#
# $1: mod name
# REPLY: null
# return: null
#
# example:
#   z.install.mod git
z.install.mod() {
  local mod_name=$1
  local github_repo="milkeclair/z"
  local github_branch=${Z_INSTALL_BRANCH:-main}
  local install_dir="$Z_ROOT/mod"
  local temp_dir
  local source_dir
  local mod_source_dir="$source_dir/mod/$mod_name"
  local mod_target_dir="$install_dir/$mod_name"
  local z_main_path="$Z_ROOT/main.zsh"

  z.install.mod._validate_name || return 1
  z.install.mod._validate_z_root || return 1

  z.install.mod._start

  z.install.mod._question_overwrite_mod_dir || return 1
  z.install._create_temp_dir || return 1

  z.install._download_archive || return 1
  z.install._decompress_archive || return 1
  z.install.mod._remove_existing_mod_dir || return 1
  z.install.mod._copy_mod_files || return 1
  z.install.mod._show_completion

  if [[ -f $z_main_path ]]; then
    source "$z_main_path"
  fi
}
