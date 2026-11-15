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

  echo "$content" >> $file
}

# write literal content to a file without interpreting escape sequences
#
# $path: file path
# $content: literal content, including an empty string
# $overwrite?: allow replacement of an existing file (default: true)
# REPLY: null
# return: 0 if written, otherwise 1
#
# example:
#  z.file.write.literal path=/tmp/example content='a\nb' overwrite=false
z.file.write.literal() {
  z.arg.named.literal path "$@" && local file=$REPLY
  z.arg.named.literal content "$@" && local content=$REPLY
  z.arg.named overwrite "$@" default=true && local overwrite=$REPLY
  z.is.null "$file" && return 1

  setopt localoptions
  if z.is.true "$overwrite"; then
    setopt clobber
  else
    setopt noclobber
  fi

  print -rn -- "$content" > "$file"
}
