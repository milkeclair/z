z.uninstall.mod._validate_name() {
  if [[ -z $mod_name ]]; then
    echo "❌ mod name is required"
    echo "   usage: z.uninstall.mod <mod_name>"
    return 1
  fi
}

z.uninstall.mod._validate_z_root() {
  if [[ -z $Z_ROOT ]]; then
    echo "❌ Z_ROOT is not set"
    echo "   source main.zsh first"
    return 1
  fi
}

z.uninstall.mod._start() {
  echo "🗑️  uninstalling mod..."
  echo "     name: $mod_name"
  echo ""
}

z.uninstall.mod._validate_presence_of_mod_dir() {
  if [[ ! -d $mod_target_dir ]]; then
    echo "❌ mod does not exist: $mod_target_dir"
    return 1
  fi
}

z.uninstall.mod._question_remove_mod_dir() {
  echo "⚠️ removing mod directory: $mod_target_dir"
  echo ""
  echo -n "sure? (y/n): "
  read -r response
  if [[ ! $response =~ ^[yY]$ ]]; then
    echo "❌ canceled"
    return 1
  fi

  return 0
}

z.uninstall.mod._remove_mod_dir() {
  echo ""
  echo "🗑️  removing..."

  if ! rm -rf "$mod_target_dir"; then
    echo "❌ failed to remove: $mod_target_dir"
    return 1
  fi

  echo ""
}

z.uninstall.mod._show_completion() {
  echo "✅ mod uninstall completed: $mod_name"
}

# uninstall z modifier
#
# $1: mod name
# REPLY: null
# return: null
#
# example:
#   z.uninstall.mod git
z.uninstall.mod() {
  local mod_name=$1
  local mod_target_dir="$Z_ROOT/mod/$mod_name"

  z.uninstall.mod._validate_name || return 1
  z.uninstall.mod._validate_z_root || return 1

  z.uninstall.mod._start

  z.uninstall.mod._validate_presence_of_mod_dir || return 1
  z.uninstall.mod._question_remove_mod_dir || return 1
  z.uninstall.mod._remove_mod_dir || return 1
  z.uninstall.mod._show_completion

  source "${Z_ROOT}/main.zsh"
}
