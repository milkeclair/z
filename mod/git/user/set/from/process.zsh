# Gitのグローバルなuser.nameとuser.emailを現在のリポジトリへコピーする
#
# REPLY: null
# return: 0|1
#
# example:
#  # グローバルのuser.nameがmilkeclair、user.emailがmilkeclair@example.comの場合
#  z.git.user.set.from.global
#  # return: 0
#  # 変更後のローカル設定: user.name=milkeclair、user.email=milkeclair@example.com
z.git.user.set.from.global() {
  local user_name=$(git config --global user.name)
  local user_email=$(git config --global user.email)

  z.git.user.set.local "$user_name" "$user_email"
}
