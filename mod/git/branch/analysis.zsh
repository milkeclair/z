# 現在のブランチを表示する
#
# REPLY: 現在のブランチ名
# return: null
#
# example:
#  # カレントブランチがmainの場合
#  z.git.branch.current
#  # 出力: main
z.git.branch.current() {
  z.git.branch.current._get && local current=$REPLY

  z.io $current
}
