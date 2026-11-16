# 選択した配布ブランチの利用可能なmodと導入済みmodを一覧する
# 緑: 導入済み、オレンジ: 内容が異なる、赤: 未導入
# ローカルでの編集も更新ありとして表示する
#
# REPLY: null
# return: 0|1
#
# example:
#  z.install.mod.list
z.install.mod.list() {
  local work_dir=$(mktemp -d)
  z.dir.exists "$work_dir" || return 1

  {
    z.install.mod._fetch dir="$work_dir" branch="${Z_INSTALL_BRANCH:-main}" || return 1
    local source_dir=$REPLY

    local names=("$source_dir"/*(N/:t) "$z_root"/mod/*(N/:t))
    z.arr.unique "${names[@]}"
    z.arr.sort "${(@)REPLY}"
    local mod_names=(${(@)REPLY})

    for mod_name in "${mod_names[@]}"; do
      z.install.mod.list._status source="$source_dir/$mod_name" installed="$z_root/mod/$mod_name" || return 1
      local mod_state=$REPLY
      local color=green

      case $mod_state in
      update-available) color=orange ;;
      not-installed) color=red ;;
      esac

      z.io color="$color" "$mod_name [$mod_state]"
    done
  } always {
    z.dir.remove path="$work_dir" || return 1
  }

  REPLY=""
}

# 選択した配布内容のmodディレクトリを作業ディレクトリへ取得する
#
# $dir: 存在する作業ディレクトリ
# $branch?: 配布ブランチ（既定: main）
# REPLY: 取り出したmodディレクトリ
# return: 0|1
#
# example:
#  z.install.mod._fetch dir=/tmp/mod-list branch=main
z.install.mod._fetch() {
  z.arg.named dir "$@" && local dir=$REPLY
  z.arg.named branch "$@" default=main && local branch=$REPLY

  local archive="$dir/source.tar.gz"
  local url="https://github.com/milkeclair/z/archive/refs/heads/$branch.tar.gz"

  curl -fLsS "$url" -o "$archive" || return 1
  tar -xzf "$archive" -C "$dir" || return 1

  local roots=("$dir"/*(N/))
  if ! z.int.is.eq ${#roots} 1 || z.dir.not.exists "$roots[1]/mod"; then
    z.io.error "mod directory not found in the distribution"
    return 1
  fi

  REPLY="$roots[1]/mod"
}

# 1回の確認後に配布対象の全modを導入または更新する
# ローカルだけにあるmodとmod直下のファイルは保持する
#
# REPLY: null
# return: 0|1
#
# example:
#  z.install.mod.all
z.install.mod.all() {
  z.is.null "$z_root" && return 1
  local install_dir=$z_root
  z.str.is.path_like "$install_dir" || install_dir="./$install_dir"
  z.path.real "$install_dir"
  install_dir=$REPLY
  z.file.exists "$install_dir/main.zsh" || return 1

  z.path.real "$PWD"
  local previous_dir=$REPLY
  local work_dir=$(mktemp -d "$install_dir/.z-mod-all.XXXXXX")
  z.dir.exists "$work_dir" || return 1

  {
    z.install.mod._fetch dir="$work_dir" branch="${Z_INSTALL_BRANCH:-main}" || return 1
    local source_dir=$REPLY
    local mod_names=("$source_dir"/*(N/:t))

    if z.int.is.zero ${#mod_names}; then
      z.io "No mods available."
      return 0
    fi

    z.install.mod.all._confirm dir="$install_dir/mod" || return 1
    z.install.mod.all._prepare source="$source_dir" current="$install_dir/mod" dir="$work_dir/next" || return 1

    if (( ${+functions[z.completion.cache._cancel]} )); then
      z.completion.cache._cancel
    fi

    z.install.mod.all._replace current="$install_dir/mod" prepared="$work_dir/next" backup="$work_dir/previous" || return 1
    z.install.mod.all._reload dir="$install_dir" previous="$previous_dir" || return 1

    z.io "Installed or updated ${#mod_names} mods."
  } always {
    local result_code=$?

    if z.int.is.not.zero "$result_code" && z.dir.exists "$work_dir/previous"; then
      z.io.error "mod recovery files: $work_dir/previous"
    else
      z.dir.remove path="$work_dir" || return 1
    fi

    REPLY=""
  }
}
