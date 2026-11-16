# ホームディレクトリのZsh設定を現在のシェルで読み直す
#
# REPLY: sourceした設定が残した値
# return: sourceの終了コード
#
# example:
#  z.reload
z.reload() {
  source "$HOME/.zshrc"
}
