# Gitの作業ツリーに変更があるか確認する
#
# REPLY: null
# return: 0|1
#
# example:
#  # 作業ツリーに未コミットの変更がある場合
#  z.git.status._is.dirty
#  # return: 0
z.git.status._is.dirty() {
  z.is.not.null "$(git status --porcelain)"
}
