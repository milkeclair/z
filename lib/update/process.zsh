# 読み込み済みのインストール先と導入済みmodを更新する
#
# REPLY: null
# return: 0|1
#
# example:
#  # Git作業ツリーではない導入済みzで、確認にyを入力して更新に成功した場合
#  z.update
#  # return: 0
#  # REPLY: ""
z.update() {
  z.arr.count "$@"
  z.int.is.zero $REPLY || return 1

  local loaded_dir=${z_root:-${Z_ROOT:-}}
  z.is.null "$loaded_dir" && return 1

  z.str.is.path_like "$loaded_dir" || loaded_dir="./$loaded_dir"
  z.path.real "$loaded_dir"
  local install_dir=$REPLY

  z.update.installation.is._valid dir="$install_dir" || return 1

  z.update._confirm dir="$install_dir" || return 1

  z.path.real "$PWD"
  local previous_dir=$REPLY

  z.path.dir "$install_dir"
  local parent_dir=$REPLY
  local work_dir=$(mktemp -d "$parent_dir/.z-update.XXXXXX")
  z.dir.exists "$work_dir" || return 1

  local installed_mods=("$install_dir"/mod/*(N/:t))

  {
    z.update.archive._download dir="$work_dir" branch="${Z_INSTALL_BRANCH:-main}" || return 1
    local archive=$REPLY

    z.update.archive._extract file="$archive" dir="$work_dir/source" || return 1
    local source_dir=$REPLY

    z.update.mod._resolve source="$source_dir" "${installed_mods[@]}" || return 1
    local mod_names=(${(@)REPLY})

    z.update.core._copy source="$source_dir" dir="$work_dir/next" || return 1

    z.update.mod._copy source="$source_dir" current="$install_dir" dir="$work_dir/next" "${mod_names[@]}" || return 1

    z.update.installation._replace dir="$install_dir" prepared="$work_dir/next" backup="$work_dir/previous" || return 1

    z.update.installation._reload dir="$install_dir" previous="$previous_dir" || return 1
  } always {
    local update_status=$?

    if z.int.is.not.zero $update_status && z.dir.exists "$work_dir/previous"; then
      z.io.error "update recovery files: $work_dir/previous"
    else
      z.dir.remove path="$work_dir"
    fi
  }

  REPLY=""
}

# インストール済み環境の更新を確認する
#
# $dir: インストール先ディレクトリ
# REPLY: null
# return: y/Yなら0、それ以外は1
#
# example:
#  # 確認にyを入力した場合
#  z.update._confirm dir=~/.z
#  # return: 0
#  # REPLY: ""
z.update._confirm() {
  z.arg.named dir "$@"
  local dir=$REPLY
  z.is.null "$dir" && return 1

  z.io.oneline "Update $dir and its installed mods? (y/n): "
  z.io.read || return 1
  local response=$REPLY

  if z.is.eq "$response" y || z.is.eq "$response" Y; then
    REPLY=""
    return 0
  fi

  REPLY=""
  return 1
}
