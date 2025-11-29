for read_file in ${z_root}/lib/file/read/*.zsh; do
  source ${read_file}
done

for write_file in ${z_root}/lib/file/write/*.zsh; do
  source ${write_file}
done

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
  z.arg.named with_dir default=false $@ && local with_dir=$REPLY

  if z.is_true $with_dir; then
    z.dir.make path=$(dirname $file)
  fi

  z.file.not_exist $file && touch $file >/dev/null 2>&1
}

# write content to a file (overwrite)
#
# $path: file path
# $content: content to write
# REPLY: null
# return: null
#
# example:
#  z.file.write path="/path/to/file.txt" content="hello world"
z.file.write() {
  z.arg.named path $@ && local file=$REPLY
  z.arg.named content $@ && local content=$REPLY

  echo -n "$content" > "$file"
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

  if z.file.exist $file; then
    REPLY=$(cat "$file")
  else
    z.return
  fi
}

