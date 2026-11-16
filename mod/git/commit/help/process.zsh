# コミットのヘルプを表示する
#
# REPLY: null
# return: null
#
# example:
#  # ローカル設定のuser.nameがmilkeclair、user.emailがmilkeclair@example.comの場合
#  z.git.commit.help._committer
#  # 出力: $'\n--- committer ---\nname: milkeclair\nemail: milkeclair@example.com\n'
z.git.commit.help._committer() {
  z.io.line
  z.io "--- committer ---"
  z.io "name: $(git config --local user.name)"
  z.io "email: $(git config --local user.email)"
}
