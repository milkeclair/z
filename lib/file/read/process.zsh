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
    REPLY=$(grep "$word" "$file" | head -n 1)
  else
    z.return
  fi
}
