z.git.commit.arg.is.not.no_ticket() {
  z.arg.named opts $@ && local opts=$REPLY

  z.str.is.not.match " ${opts[*]} " " -nt "
}
