# コミット引数を取り出す
#
# $@: コミット引数
# REPLY: コミットオプションの配列
# return: null
#
# example:
#  z.git.commit._arg.extract.opts opts_count 2 opts_1 "-ca" opts_2 "-ae"
#  # REPLY: ("-ca" "-ae")
z.git.commit._arg.extract.opts() {
  local -A args=("${(@)@}")
  local opts=()

  local idx=1
  while z.int.is.lteq $idx ${args[opts_count]:-0}; do
    opts+=(${args[opts_$idx]})
    ((idx++))
  done

  REPLY=("${opts[@]}")
}
