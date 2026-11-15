# get the rest of a string after removing a matching prefix
#
# $1: string
# $2: regex to match at the beginning
# REPLY: the rest of the string after the matched prefix, or empty if no match
# return: null
#
# example:
#  z.str.match.rest "hello_world" "hello_" #=> "world"
#  z.str.match.rest "foo-bar-baz" "foo-"   #=> "bar-baz"
z.str.match.rest() {
  local str=$1
  local regex=$2

  if z.str.is.match "$str" "^(${regex})"; then
    z.return ${str[MEND + 1,-1]}
  else
    z.return
  fi
}

# get the nth element from a string that matches a regex
#
# $1: string (space-separated elements)
# $2: regex
# $index: 1-based index of the matching element to return
# REPLY: the nth matching element, or empty if not found
# return: null
#
# example:
#  z.str.match.nth "one two three" "^o" index=1   #=> "one"
#  z.str.match.nth "apple banana cherry" "^a" index=2 #=> "banana"
z.str.match.nth() {
  z.arg.named index $@ && local index=$REPLY
  z.arg.named.shift index $@
  local str=$REPLY[1]
  local regex=$REPLY[2]

  local words=( ${=str} )
  local count=0

  for word in $words; do
    if z.str.is.match "$word" "$regex"; then
      ((count++))
      if z.int.is.eq $count $index; then
        z.return $word
        return
      fi
    fi
  done

  z.return
}
