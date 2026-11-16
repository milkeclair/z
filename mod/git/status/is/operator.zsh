# Gitの作業ツリーに変更があるか確認する
#
# REPLY: null
# return: 0|1
#
# example:
#  if z.git.status._is.dirty; then
z.git.status._is.dirty() {
  z.is.not.null "$(git status --porcelain)"
}
