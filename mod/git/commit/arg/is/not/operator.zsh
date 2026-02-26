# check if commit args do not contain -nt (no ticket)
#
# $@: commit args
# REPLY: null
# return: 0|1
#
# example:
#   z.git.commit.arg.is.not.no_ticket -m "commit message" #=> true
#   z.git.commit.arg.is.not.no_ticket -m "commit message" -nt #=> false
z.git.commit.arg.is.not.no_ticket() {
  z.arg.named opts $@ && local opts=$REPLY

  z.str.is.not.match " ${opts[*]} " " -nt "
}
