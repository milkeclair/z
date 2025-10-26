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

# create a file if it does not exist, along with its parent directories
#
# $path: file path
# REPLY: null
# return: null
#
# example:
#  z.file.make_with_dir path="/path/to/file.txt"
z.file.make_with_dir() {
  z.arg.named path $@ && local file=$REPLY

  z.dir.make path=$(dirname $file)
  z.file.make path=$file
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

# read lines from a file into an array
#
# $path: file path
# REPLY: array of lines
# return: null
#
# example:
#  z.file.read.lines path="/path/to/file.txt"
z.file.read.lines() {
  z.arg.named path $@ && local file=$REPLY

  if z.file.exist $file; then
    REPLY=(${(@f)$(cat "$file")})
  else
    z.return
  fi
}

# pick a line containing a specific word from a file
#
# $path: file path
# $word: word to search for
# REPLY: line containing the word|null
# return: null
#
# example:
#  z.file.read.pick path="/path/to/file.txt" word="search_word"
z.file.read.pick() {
  z.arg.named path $@ && local file=$REPLY
  z.arg.named word $@ && local word=$REPLY

  if z.file.exist $file; then
    REPLY=$(grep -w "$word" "$file" | head -n 1)
  else
    z.return
  fi
}
