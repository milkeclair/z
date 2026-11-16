# コミット引数を取り出す
# 結果は連想配列のキーと値の組なので、呼び出し元で連想配列に組み立てられる
#
# $@: コミット引数
# REPLY: コミットオプションの配列
# return: null
#
# example:
#  z.git.commit._arg.extract feat "add new feature" TICKET-123 -ca -ae
#  # REPLY: ("tag" "feat" "message" "add new feature" "ticket" "TICKET-123" "opts_count" "2" "opts_1" "-ca" "opts_2" "-ae")
z.git.commit._arg.extract() {
  local tag=$1
  local message=$2
  local ticket=""
  local opts=()
  shift 2

  for arg in "$@"; do
    if z.str.start_with "$arg" "-"; then
      opts+=($arg)
    elif z.is.null $ticket; then
      ticket=$arg
    fi
  done

  local result=(
    tag "$tag"
    message "$message"
    ticket "$ticket"
    opts_count "${#opts[@]}"
  )

  local idx=1
  for opt in ${opts[@]}; do
    result+=(opts_$idx "$opt")
    ((idx++))
  done

  REPLY=("${result[@]}")
}
