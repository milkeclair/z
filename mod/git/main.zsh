# z.git.modeへ委譲する
#
# REPLY: null
# return: null
#
# example:
#  z.git
#  # 入力例: add file.txt
#  # 実行される操作: z.git.add file.txt
#  # 結果: file.txtがステージされる
z.git() {
  z.git.mode
}
