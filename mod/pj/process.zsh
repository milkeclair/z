# 登録済みプロジェクトをVisual Studio Codeで開く
#
# $1: プロジェクト名
# REPLY: null
# return: codeの終了コード。入力不正または未登録のプロジェクトなら1
#
# example:
#  z.pj some_project
z.pj() {
  z.arr.count "$@"
  if z.int.is.not.eq $REPLY 1; then
    z.io.error "Usage: z.pj <name>"
    return 1
  fi

  z.pj.file._directory "$1" || return 1
  local dir=$REPLY
  if z.dir.not.exists "$dir"; then
    z.io.error "Project directory does not exist: $dir"
    return 1
  fi
  if ! z.io.null whence code; then
    z.io.error "Visual Studio Code command is not available: code"
    return 1
  fi

  REPLY=""
  code "$dir"
}

# 既存の名前を上書きせず、プロジェクトのディレクトリを登録する
#
# $name: プロジェクト名
# $dir: 存在するプロジェクトディレクトリ
# REPLY: null
# return: 0|1
#
# example:
#  z.pj.add name=some_project dir=~/repo/p/some
z.pj.add() {
  z.arg.named name "$@" && local name=$REPLY
  z.arg.named dir "$@" && local dir=$REPLY

  z.pj.add._directory "$dir" || return 1
  local project_dir=$REPLY
  z.pj.add._write name="$name" dir="$project_dir" || return 1

  z.io message="Registered: $name -> $project_dir"
  REPLY=""
}

# 登録済みのプロジェクト名とディレクトリを一覧する
#
# REPLY: null
# return: 0|1
#
# example:
#  z.pj.list
z.pj.list() {
  z.pj.file._names
  local names=("${(@)REPLY}")
  z.arr.count "${names[@]}"
  if z.int.is.zero $REPLY; then
    z.io "No projects registered."
    REPLY=""
    return 0
  fi

  local name
  for name in "${names[@]}"; do
    z.pj.file._directory "$name" || return 1
    z.io message="$name"$'\t'"$REPLY"
  done
  REPLY=""
}

# 名前または番号で選び、プロジェクトの登録を削除する
#
# $1?: プロジェクト名。省略すると登録済みの名前から選ぶ
# REPLY: null
# return: 削除またはキャンセルした場合は0、それ以外は1
#
# example:
#  z.pj.remove some_project
#  z.pj.remove
z.pj.remove() {
  z.arr.count "$@" && local arg_count=$REPLY
  if z.int.is.gt $arg_count 1; then
    z.io.error "Usage: z.pj.remove [name]"
    return 1
  fi

  local name=$1
  if z.int.is.zero $arg_count; then
    z.pj.remove._select || return 1
    name=$REPLY
    z.is.null "$name" && return 0
  fi

  z.pj.remove._entry "$name" || return 1
  z.io "Removed: $name"
  REPLY=""
}
