# noop block for grouping
#
# return: 0
# REPLY: null
#
# example:
#  z.guard; { ... }
#  z.group "group_name"; { ... }
z.group() {
  return 0
}

# noop block for guarding
#
# return: 0
# REPLY: null
#
# example:
#  z.guard; { ... }
#  z.guard "guard_name"; { ... }
z.guard() {
  return 0
}
