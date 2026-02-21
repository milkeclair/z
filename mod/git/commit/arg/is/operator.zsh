z.git.commit.arg.is.enough() {
  local tag_and_message=2

  z.arr.count $@
  if z.int.is.lt $REPLY $tag_and_message; then
    z.io.line
    z.git.commit.help
    return 1
  fi
}

z.git.commit.arg.is.no_ticket() {
  z.arg.named opts $@ && local opts=$REPLY

  z.str.is.not.match " ${opts[*]} " " -nt "
}
