# 処理をまとめるための何もしないブロック
#
# return: 0
# REPLY: null
#
# example:
#  z.group "example"; {
#    z.io "hello"
#  }
#  # 出力: hello
z.group() {
  return 0
}

# ガードを記述するための何もしないブロック
#
# return: 0
# REPLY: null
#
# example:
#  z.guard
#  # return: 0
#  z.guard "guard_name"
#  # return: 0
z.guard() {
  return 0
}
