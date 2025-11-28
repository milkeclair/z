# append content to the end of a file
#
# $path: file path
# $content: content to append
# REPLY: null
# return: null
#
# example:
#  z.file.write.last path="/path/to/file.txt" content="hello world"
z.file.write.last() {
  z.arg.named path $@ && local file=$REPLY
  z.arg.named content $@ && local content=$REPLY

  echo "$content" >> "$file"
}
