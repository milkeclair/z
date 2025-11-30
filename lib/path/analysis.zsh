# get the current working directory
#
# REPLY: current working directory path
# return: null
#
# example:
#   z.path.current
#   echo $REPLY  # outputs "/home/user"
z.path.current() {
  z.return $(pwd)
}

# get the home directory path
#
# REPLY: home directory path
# return: null
#
# example:
#   z.path.home
#   echo $REPLY  # outputs "/home/username"
z.path.home() {
  z.return $HOME
}
