# 登録名を番号付きで標準エラーへ表示する
#
# $@: 表示順に並べたプロジェクト名
# REPLY: null
# return: null
#
# example:
#  z.pj.remove._menu first second
#  # 標準エラー:
#  # 1) first
#  # 2) second
z.pj.remove._menu() {
  local index=1
  local name
  for name in "$@"; do
    z.io "$index) $name" >&2
    ((index++))
  done
}

# 登録内容を変更せず、登録済みのプロジェクトを選ぶ
#
# REPLY: 選択した名前。キャンセル時は空
# return: 0|1
#
# example:
#  # 登録名がfirst、secondで、1を入力した場合
#  z.pj.remove._select
#  # REPLY: "first"
#  # return: 0
z.pj.remove._select() {
  z.pj.file._names
  local names=("${(@)REPLY}")
  z.arr.count "${names[@]}"
  if z.int.is.zero $REPLY; then
    z.io "No projects registered." >&2
    REPLY=""
    return 0
  fi

  z.pj.remove._menu "${names[@]}"
  z.io.oneline "Project number (empty to cancel): " >&2
  if ! z.io.read || z.is.null "$REPLY"; then
    REPLY=""
    return 0
  fi

  local selection=$REPLY
  local index=1
  local name
  for name in "${names[@]}"; do
    if z.is.eq "$selection" "$index"; then
      REPLY=$name
      return 0
    fi
    ((index++))
  done
  z.io.error "Invalid project number: $selection"
  REPLY=""
  return 1
}

# 検証済みの名前に対応する通常の登録ファイルだけを削除する
#
# $1: プロジェクト名
# REPLY: null
# return: 0|1
#
# example:
#  # exampleの登録ファイルが存在する場合
#  z.pj.remove._entry example
#  # return: 0
#  # 結果: exampleの登録ファイルが削除される
z.pj.remove._entry() {
  z.pj.file._path "$1" || return 1
  local file=$REPLY
  if ! z.pj.file.is.registration "$file"; then
    z.io.error "Project is not registered: $1"
    return 1
  fi

  rm -- "$file"
}
