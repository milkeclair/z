# 整形したGitのログを表示する
#
# REPLY: null
# return: null
#
# example:
#  # 最新コミットがabc1234、日時が2026/06/23 12:15、作成者がAliceの場合
#  z.git.log
#  # 出力例（ユーザー設定の表示に続くコミット部分、色指定を省略）:
#  # *  abc1234 [26/06/23 12:15] Alice (HEAD -> main)
#  #    add new feature
z.git.log() {
  z.git.user

  z.io.empty
  z.io "--- commits ---"
  z.git.log._pretty
}

# 整形したGitのログを表示する
#
# REPLY: null
# return: null
#
# example:
#  # 最新コミットがabc1234、日時が2026/06/23 12:15、作成者がAliceの場合
#  z.git.log._pretty
#  # 出力例（色指定を省略）:
#  # *  abc1234 [26/06/23 12:15] Alice (HEAD -> main)
#  #    add new feature
z.git.log._pretty() {
  git log --graph --date=format:'%y/%m/%d %R' --pretty=format:' %C(yellow)%h%Creset [%C(green)%cd%Creset] %C(cyan)%cn%Creset%C(auto)%d%Creset%n %s%n%w(120,1,1)%b'
}
