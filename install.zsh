# install z
#
# $1: install dir (default: $HOME/.z)
# REPLY: null
# return: null
#
# example:
#   1. z.install
#   2. z.install /path/to/dir
z.install() {
  local install_dir=${1:-$HOME/.z}
  local github_repo="milkeclair/z"
  local github_branch=${Z_INSTALL_BRANCH:-main}
  local temp_dir
  local source_dir

  z.install._replace_home

  z.install._start

  z.install._question_overwrite_install_dir || return 1
  z.install._create_temp_dir || return 1

  z.install._setup_cleanup

  z.install._download_archive || return 1
  z.install._decompress_archive || return 1
  z.install._copy_files || return 1
  z.install._show_completion

  if z.install._zshrc_exists; then
    if z.install._question_add_to_zshrc; then
      z.install._add_to_zshrc
    fi
  fi
}

# private

z.install._replace_home() {
  install_dir=${install_dir/#\~/$HOME}

  if [[ $install_dir != /* ]]; then
    install_dir=$PWD/$install_dir
  fi
}

z.install._start() {
  echo "📦 installing z..."
  echo "     github: https://github.com/$github_repo"
  echo "     branch: $github_branch"
  echo "     install dir: $install_dir"
  echo ""
}

z.install._question_overwrite_install_dir() {
  if [[ ! -d $install_dir ]]; then
    return 0
  fi

  echo "⚠️ install dir already exists: $install_dir"
  echo -n "overwrite? (y/n): "
  read -r response
  if [[ ! $response =~ ^[yY]$ ]]; then
    echo "❌ canceled"
    return 1
  fi
  echo ""
}

z.install._create_temp_dir() {
  temp_dir=$(mktemp -d)
  if [[ ! -d $temp_dir ]]; then
    echo "❌ failed to create temp dir"
    return 1
  fi
}

z.install._setup_cleanup() {
  z.install._cleanup() {
    if [[ -d $temp_dir ]]; then
      rm -rf $temp_dir
    fi
  }
  
  trap z.install._cleanup EXIT
}

z.install._download_archive() {
  echo "💤 downloading..."
  local archive_url="https://github.com/$github_repo/archive/refs/heads/$github_branch.tar.gz"

  if ! curl -sL $archive_url -o "$temp_dir/z.tar.gz"; then
    echo "❌ failed to download"
    return 1
  fi
}

z.install._decompress_archive() {
  echo "📦: decompressing..."
  if ! tar -xzf "$temp_dir/z.tar.gz" -C $temp_dir; then
    echo "❌ failed to decompress"
    return 1
  fi

  source_dir="$temp_dir/z-$github_branch"
  if [[ ! -d $source_dir ]]; then
    echo "❌ directory does not exist: $source_dir"
    return 1
  fi
}

z.install._copy_files() {
  if ! mkdir -p $install_dir; then
    echo "❌ failed to create install dir: $install_dir"
    return 1
  fi

  local lib_dir="$source_dir/lib"
  if [[ ! -d $lib_dir ]]; then
    echo "❌ lib directory does not exist: $lib_dir"
    return 1
  fi

  local test_dir="$source_dir/test"
  if [[ ! -d $test_dir ]]; then
    echo "❌ test directory does not exist: $test_dir"
    return 1
  fi

  echo "   📁 lib/"
  if ! cp -r $lib_dir "$install_dir/"; then
    echo "❌ failed to copy: lib/"
    return 1
  fi

  echo "   📁 test/"
  if ! cp -r $test_dir "$install_dir/"; then
    echo "❌ failed to copy: test/"
    return 1
  fi

  local file="main.zsh"

  if [[ -f "$source_dir/$file" ]]; then
    echo "   📄 $file"
    if ! cp "$source_dir/$file" "$install_dir/"; then
      echo "❌ failed to copy: $file"
      return 1
    fi
  fi
}

z.install._show_completion() {
  echo ""
  echo "✅ installation completed!"
  echo ""
  echo "Usage:"
  echo "   add the following lines to your ~/.zshrc:"
  echo ""
  echo "   export Z_ROOT=\"$install_dir\""
  echo "   export Z_TEST_ROOT=\"$install_dir/test\""
  echo "   source \"\$Z_ROOT/main.zsh\""
  echo ""
}

z.install._zshrc_exists() {
  if [[ -f "$HOME/.zshrc" ]]; then
    return 0
  fi

  return 1
}

z.install._question_add_to_zshrc() {
  echo -n "add to .zshrc? (y/n): "
  read -r response

  if [[ ! $response =~ ^[yY]$ ]]; then
    return 1
  fi
}

z.install._zshrc_has_source_line() {
  if grep -qF "export Z_ROOT=" "$HOME/.zshrc" && \
     grep -qF "source \"\$Z_ROOT/main.zsh\"" "$HOME/.zshrc"; then
    return 0
  fi

  return 1
}

z.install._add_to_zshrc() {
  if z.install._zshrc_has_source_line; then
    echo "✅ already added to .zshrc"
    return 0
  fi

  echo "" >> "$HOME/.zshrc"
  echo "# z configuration" >> "$HOME/.zshrc"
  echo "export Z_ROOT=\"$install_dir\"" >> "$HOME/.zshrc"
  echo "export Z_TEST_ROOT=\"\$Z_ROOT/test\"" >> "$HOME/.zshrc"
  echo "source \"\$Z_ROOT/main.zsh\"" >> "$HOME/.zshrc"
  echo "✅ added to .zshrc"
  echo "   to apply changes: source ~/.zshrc"
}

z.install
