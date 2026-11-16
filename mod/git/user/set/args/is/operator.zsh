# Gitのユーザー設定に必要な引数が揃っているか確認する
#
# $1: user.nameの値
# $2: user.emailの値
# REPLY: null
# return: 0|1
#
# example:
#  z.git.user.set._arg.is.enough "milkeclair" "milkeclair@example.com"
#  # return: 0
#  z.git.user.set._arg.is.enough "" "milkeclair@example.com"
#  # return: 1
#  z.git.user.set._arg.is.enough "milkeclair" ""
#  # return: 1
z.git.user.set._arg.is.enough() {
  if z.is.null $1 && z.is.null $2; then
    z.io "require user.name"
    z.io "require user.email"
    return 1
  elif z.is.null $1; then
    z.io "require user.name"
    return 1
  elif z.is.null $2; then
    z.io "require user.email"
    return 1
  fi
}
