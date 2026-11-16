# コミットオプションを取り出す
#
# $@: コミット引数
# REPLY: 有効なコミットオプションの配列
# return: null
#
# example:
#  z.git.commit._opts.extract -m "commit message" -ca -ae
#  # REPLY: ("--amend" "--allow-empty")
z.git.commit._opts.extract() {
  local opts=()
  local valid_opts=()

  for arg in "$@"; do
    if z.str.start_with "$arg" "-"; then
      opts+=($arg)
    fi
  done

  for opt in ${opts[@]}; do
    if z.is.eq $opt -ca; then
      valid_opts+=(--amend)
    elif z.is.eq $opt -ae; then
      valid_opts+=(--allow-empty)
    fi
  done

  REPLY=("${valid_opts[@]}")
}
