# remove a literal prefix from a string
#
# $1: original string
# $2: prefix
# REPLY: string without the prefix, or the original string if the prefix is not present
# return: null
#
# example:
#  z.str.remove.prefix "pr/123" "pr/" #=> "123"
#  z.str.remove.prefix "main" "pr/"   #=> "main"
z.str.remove.prefix() {
  local str=$1
  local prefix=$2

  if z.str.start_with "$str" "$prefix"; then
    z.return "${str[${#prefix} + 1,-1]}"
  else
    z.return "$str"
  fi
}

# remove a literal suffix from a string
#
# $1: original string
# $2: suffix
# REPLY: string without the suffix, or the original string if the suffix is not present
# return: null
#
# example:
#  z.str.remove.suffix "file.zsh" ".zsh" #=> "file"
#  z.str.remove.suffix "README" ".md"    #=> "README"
z.str.remove.suffix() {
  local str=$1
  local suffix=$2

  if z.str.end_with "$str" "$suffix"; then
    z.return "${str[1,${#str} - ${#suffix}]}"
  else
    z.return "$str"
  fi
}
