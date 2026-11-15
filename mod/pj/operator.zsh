# check whether a project name can be used as a registry file name
#
# $1: project name
# REPLY: null
# return: 0 for a valid name, otherwise 1
#
# example:
#  z.pj._valid_name some_project
z.pj._valid_name() {
  local pattern='^[A-Za-z0-9_][A-Za-z0-9_.-]*$'
  [[ ${1:-} =~ $pattern ]]
}
