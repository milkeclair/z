# check whether a project name can be used as a registry file name
#
# $1: project name
# REPLY: null
# return: 0|1
#
# example:
#  z.pj.name.is.valid some_project
z.pj.name.is.valid() {
  local pattern='^[A-Za-z0-9_][A-Za-z0-9_.-]*$'
  z.str.is.match "$1" "$pattern"
}
