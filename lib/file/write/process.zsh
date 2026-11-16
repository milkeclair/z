# ファイルの末尾に内容を追記する
#
# $path: ファイルのパス
# $content: 追記する内容
# REPLY: null
# return: null
#
# example:
#  # /tmp/z-example.txtの最初の行がfirstの場合
#  z.file.write.last path=/tmp/z-example.txt content="hello world"
#  z.file.read path=/tmp/z-example.txt
#  # REPLY: $'first\nhello world'
z.file.write.last() {
  z.arg.named path $@ && local file=$REPLY
  z.arg.named content $@ && local content=$REPLY

  echo "$content" >> $file
}
