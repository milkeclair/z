# Gitの対話モード
#
# REPLY: null
# return: null
#
# example:
#  z.git.mode
#  # 入力例: add file.txt
#  # 実行される操作: z.git.add file.txt
#  # 結果: file.txtがステージされる
z.git.mode() {
  z.mode z.git split=.
}
