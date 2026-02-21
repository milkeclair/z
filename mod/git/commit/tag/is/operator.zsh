z.git.commit.tag.is.valid() {
  z.git.commit.tag.list && local tag_list=$REPLY
  local tag=$1

  if z.str.is.not.match " ${tag_list[*]} " " $tag "; then
    z.io.line
    z.git.commit.help
    return 1
  fi
}
