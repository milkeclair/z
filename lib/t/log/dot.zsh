# 成功したテストを緑のドットで表示する
#
# REPLY: null
# return: null
#
# example:
#  z.t._log.dot.success
z.t._log.dot.success() {
  z.t._log.dot.output char=.
}

# 失敗したテストを赤のドットで表示する
#
# REPLY: null
# return: null
#
# example:
#  z.t._log.dot.failure
z.t._log.dot.failure() {
  z.t._log.dot.output char=F
}

# 保留したテストを黄のドットで表示する
#
# REPLY: null
# return: null
#
# example:
#  z.t._log.dot.pending
z.t._log.dot.pending() {
  z.t._log.dot.output "char=*"
}

# 内部用: 折り返しながら色付きのドットを表示する
#
# $char: 結果表示用の文字（. F *）
# REPLY: null
# return: null
#
# example:
#  z.t._log.dot.output char=F
z.t._log.dot.output() {
  z.arg.named char $@ && local char=$REPLY
  local count_file="${Z_TEST_COMPACT_DIR}/.dot_count"
  local count=0

  z.file.exists $count_file && count=$(cat $count_file)

  local terminal_width=${COLUMNS:-77}
  local width=77
  z.int.is.lt $terminal_width 77 && width=$terminal_width

  if z.int.is.eq $((count % width)) 0 && z.int.is.gt $count 0; then
    z.io.line
  fi

  case $char in
    "F") z.str.color.red $char ;;
    "*") z.str.color.yellow $char ;;
    *) z.str.color.green $char ;;
  esac

  printf "%s" $REPLY
  echo $((count + 1)) > $count_file
}
