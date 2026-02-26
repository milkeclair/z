# git add
# prevent "git add ." to encourage users to specify files explicitly
#
# $@: files
# REPLY: null
# return: null
#
# example:
#   z.git.add file1.txt file2.txt
z.git.add() {
  z.arg.first $@ && local first_arg=$REPLY
  z.is.eq $first_arg "add" && shift

  if z.is.eq $first_arg "."; then
    z.io 'Rejecting "git add ." command. Please specify the files to add explicitly.'
    return 1
  fi

  command git add "$@"
}
