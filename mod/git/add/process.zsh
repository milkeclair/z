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
  if z.is.eq $1 "."; then
    z.io 'Rejecting "git add ." command. Please specify the files to add explicitly.'
    return 1
  fi

  command git add "$@"
}
