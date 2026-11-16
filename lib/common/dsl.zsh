# 処理をまとめるための何もしないブロック
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

# ガードを記述するための何もしないブロック
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
