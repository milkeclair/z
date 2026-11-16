# create a file if it does not exist
#
# $path: file path
# $with_dir?: create parent directories if not exist(default: false)
# REPLY: null
# return: null
#
# example:
#  z.file.make path="/path/to/file.txt" with_dir=true
z.file.make() {
  z.arg.named path $@ && local file=$REPLY
  z.arg.named with_dir $@ default=false && local with_dir=$REPLY

  if z.is.true $with_dir; then
    z.dir.make path=$(dirname $file)
  fi

  z.file.not.exists $file && touch $file >/dev/null 2>&1
}

# write content to a file (overwrite)
#
# $path: file path
# $content: content to write
# $overwrite?: allow replacement of an existing file (default: true)
# REPLY: null
# return: 0 if written, otherwise 1
#
# example:
#  z.file.write path="/path/to/file.txt" content="hello world"
z.file.write() {
  z.arg.named path "$@" && local file=$REPLY
  z.arg.named content "$@" && local content=$REPLY
  z.arg.named overwrite "$@" default=true && local overwrite=$REPLY
  z.is.null "$file" && return 1

  setopt localoptions
  if z.is.true $overwrite; then
    setopt clobber
  else
    setopt noclobber
  fi

  print -rn -- "$content" > "$file"
}

# read content from a file
#
# $path: file path
# REPLY: file content
# return: null
#
# example:
#  z.file.read path="/path/to/file.txt"
z.file.read() {
  z.arg.named path $@ && local file=$REPLY

  if z.file.exists $file; then
    REPLY=$(cat $file)
  else
    REPLY=""
  fi
}

