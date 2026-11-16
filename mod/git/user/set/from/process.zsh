# Gitのグローバルなuser.nameとuser.emailを現在のリポジトリへコピーする
#
# REPLY: null
# return: 0|1
#
# example:
#   z.git.user.set.from.global
z.git.user.set.from.global() {
  local user_name=$(git config --global user.name)
  local user_email=$(git config --global user.email)

  z.git.user.set.local "$user_name" "$user_email"
}
