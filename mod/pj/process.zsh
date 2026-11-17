# 登録済みプロジェクトをVisual Studio Codeで開く
#
# $1: プロジェクト名
# REPLY: null
# return: codeの終了コード。入力不正または未登録のプロジェクトなら1
#
# example:
#  # some_project=/tmp/exampleを登録済みで、codeが0で終了する場合
#  z.pj some_project
#  # 実行されるコマンド: code /tmp/example
#  # return: 0
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
#  # /tmp/exampleが実在し、同名の登録がない場合
#  z.pj.add name=some_project dir=/tmp/example
#  # return: 0
#  # 結果: some_projectの登録先が/tmp/exampleになる
z.pj.add() {
  z.arg.named name "$@" && local name=$REPLY
  z.arg.named dir "$@" && local dir=$REPLY

  z.pj.add._directory "$dir" || return 1
  local project_dir=$REPLY
  z.pj.add._write name="$name" dir="$project_dir" || return 1

  z.io message="Registered: $name -> $project_dir"
  REPLY=""
}

# 名前を紫、パスを白にして、列を揃えてプロジェクトを一覧する
#
# REPLY: null
# return: 0|1
#
# example:
#  # some_project=/tmp/exampleだけを登録済みの場合
#  z.pj.list
#  # 出力（名前は紫、パスは白）: some_project  /tmp/example
#  # return: 0
z.pj.list() {
  z.pj.file._names
  local names=("${(@)REPLY}")
  z.arr.count "${names[@]}"
  if z.int.is.zero $REPLY; then
    z.io "No projects registered."
    REPLY=""
    return 0
  fi

  local width=0
  local name
  for name in "${names[@]}"; do
    z.int.is.gt ${#name} $width && width=${#name}
  done

  for name in "${names[@]}"; do
    z.pj.file._directory "$name" || return 1
    local dir=$REPLY
    z.str.ljust "$name" width=$width && local label=$REPLY
    z.str.color.magenta "$label" && label=$REPLY
    z.str.color.white "$dir"
    z.io message="$label  $REPLY"
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
#  # some_projectを登録済みの場合
#  z.pj.remove some_project
#  # return: 0
#  # 結果: some_projectの登録ファイルが削除され、プロジェクト本体は残る
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
