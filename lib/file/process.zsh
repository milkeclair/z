for make_file in ${z_root}/lib/file/make/*.zsh; do
  source ${make_file}
done

for read_file in ${z_root}/lib/file/read/*.zsh; do
  source ${read_file}
done

for write_file in ${z_root}/lib/file/write/*.zsh; do
  source ${write_file}
done

# create a file if it does not exist
#
# $path: file path
# REPLY: null
# return: null
#
# example:
#  z.file.make path="/path/to/file.txt"
z.file.make() {
  z.arg.named path $@ && local file=$REPLY

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

