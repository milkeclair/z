# show git log with pretty format
#
# REPLY: null
# return: null
#
# example:
#   z.git.log #=> show git log with pretty format
z.git.log() {
  z.git.user

  z.io.empty
  z.io "--- commits ---"
  z.git.log._pretty
}

# show git log with pretty format
#
# REPLY: null
# return: null
#
# example:
#   z.git.log._pretty #=> show git log with pretty format
z.git.log._pretty() {
  git log --graph --date=format:'%y/%m/%d %R' --pretty=format:' %C(yellow)%h%Creset [%C(green)%cd%Creset] %C(cyan)%cn%Creset%C(auto)%d%Creset%n %s%n%w(120,1,1)%b'
}
