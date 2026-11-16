# ホームディレクトリのZsh設定を現在のシェルで読み直す
#
# REPLY: sourceした設定が残した値
# return: sourceの終了コード
#
# example:
#  # ~/.zshrcでREPLY="ready"を設定し、最後にreturn 0する場合
#  z.reload
#  # REPLY: "ready"
#  # return: 0
z.reload() {
  source "$HOME/.zshrc"
}
