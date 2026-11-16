# 引数に-nt（チケットなし）が含まれないか確認する
#
# $@: コミット引数
# REPLY: null
# return: 0|1
#
# example:
#   z.git.commit._arg.is.not.no_ticket -m "commit message" #=> true
#   z.git.commit._arg.is.not.no_ticket -m "commit message" -nt #=> false
z.git.commit._arg.is.not.no_ticket() {
  z.arg.named opts $@ && local opts=$REPLY

  z.str.is.not.match " $opts " "[[:space:]]-nt[[:space:]]"
}
