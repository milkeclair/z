# check if commit tag is valid
#
# $1: commit tag
# REPLY: null
# return: 0|1
#
# example:
#   z.git.commit.tag.is.valid "feat" #=> true
#   z.git.commit.tag.is.valid "invalid_tag" #=> false
z.git.commit.tag.is.valid() {
  z.git.commit.tag.list && local tag_list=$REPLY
  local tag=$1

  if z.str.is.not.match " ${tag_list[*]} " "* $tag *"; then
    z.io.line
    z.git.commit.help
    return 1
  fi
}
