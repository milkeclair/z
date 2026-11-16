# ファイルの末尾に内容を追記する
#
# $path: ファイルのパス
# $content: 追記する内容
# REPLY: null
# return: null
#
# example:
#  z.file.write.last path="/path/to/file.txt" content="hello world"
z.file.write.last() {
  z.arg.named path $@ && local file=$REPLY
  z.arg.named content $@ && local content=$REPLY

  echo "$content" >> $file
}
