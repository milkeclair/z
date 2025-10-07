z.install._replace_home() {
  install_dir="${install_dir/#\~/$HOME}"

  if [[ "$install_dir" != /* ]]; then
    install_dir="$PWD/$install_dir"
  fi
} 

z.uninstall._start() {
  echo "🗑️  uninstalling z..."
  echo ""
}

z.uninstall._validate_presence_of_install_dir() {
  if [[ ! -d "$install_dir" ]]; then
    echo "❌ directory does not exist: $install_dir"
    return 1
  fi

  if [[ ! -f "$install_dir/main.zsh" ]]; then
    echo "⚠️ path $install_dir is not z library directory."
    echo ""
  fi

  return 0
}

z.uninstall._question_remove_install_dir() {
  echo "⚠️ removing directory: $install_dir"
  echo ""
  echo -n "sure? (y/n): "
  read -r response
  if [[ ! $response =~ ^[yY]$ ]]; then
    echo "❌ canceled"
    return 1
  fi

  return 0
}

z.uninstall._remove_install_dir() {
  echo ""
  echo "🗑️  removing..."

  if ! rm -rf "$install_dir"; then
    echo "❌ failed to remove: $install_dir"
    return 1
  fi

  echo ""

  return 0
}

z.uninstall._zshrc_has_source_line() {
  if [[ -f "$HOME/.zshrc" ]] && grep -qF "export Z_ROOT=" "$HOME/.zshrc"; then
    return 0
  fi

  return 1
}

z.uninstall._question_remove_source_line() {
  echo ""
  echo "📝 following lines remain in .zshrc:"
  echo "   # z configuration"
  echo "   export Z_ROOT=\"$install_dir\""
  echo "   export Z_TEST_ROOT=\"\$Z_ROOT/test\""
  echo "   source \"\$Z_ROOT/main.zsh\""
  echo ""
  echo -n "remove from .zshrc? (y/n): "
  read -r response
  if [[ ! $response =~ ^[yY]$ ]]; then
    echo "🙏 please remove it manually"
    return 1
  fi

  return 0
}

z.uninstall._remove_source_line() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' '/# z configuration/,/source "\$Z_ROOT\/main.zsh"/d' "$HOME/.zshrc"
  else
    # Linux
    sed -i '/# z configuration/,/source "\$Z_ROOT\/main.zsh"/d' "$HOME/.zshrc"
  fi
  echo "✅ removed from .zshrc"
  echo "   to apply changes: source ~/.zshrc"

  return 0
}

z.uninstall._bye() {
  echo ""
  echo "👋"
}

# uninstall z
#
# $1: install dir (default: $HOME/.z)
# REPLY: null
# return: null
#
# example:
#   1. z.uninstall
#   2. z.uninstall /path/to/dir
z.uninstall() {
  local install_dir="${1:-$HOME/.z}"

  z.install._replace_home

  z.uninstall._start

  z.uninstall._validate_presence_of_install_dir || return 1
  z.uninstall._question_remove_install_dir || return 1
  z.uninstall._remove_install_dir || return 1

  if z.uninstall._zshrc_has_source_line; then
    z.uninstall._question_remove_source_line || return 1
    z.uninstall._remove_source_line
  fi

  z.uninstall._bye

  return 0
}
