# Gitのローカル設定とグローバル設定のユーザー名・メールアドレスを表示する
#
# REPLY: null
# return: null
#
# example:
#  # local/globalの名前がmilkeclair、メールがmilkeclair@example.comの場合
#  z.git.user
#  # 出力:
#  # --- local user info ---
#  # user.name: milkeclair
#  # user.email: milkeclair@example.com
#  #
#  # --- global user info ---
#  # user.name: milkeclair
#  # user.email: milkeclair@example.com
z.git.user() {
  z.git.user.local
  z.io.line
  z.git.user.global
}

# Gitのローカル設定のユーザー名・メールアドレスを表示する
#
# REPLY: null
# return: null
#
# example:
#  # ローカル設定の名前がmilkeclair、メールがmilkeclair@example.comの場合
#  z.git.user.local
#  # 出力:
#  # --- local user info ---
#  # user.name: milkeclair
#  # user.email: milkeclair@example.com
z.git.user.local() {
  z.io "--- local user info ---"
  local user_name=$(git config --local user.name)
  local user_email=$(git config --local user.email)
  z.io "user.name: $user_name"
  z.io "user.email: $user_email"
}

# Gitのグローバル設定のユーザー名・メールアドレスを表示する
#
# REPLY: null
# return: null
#
# example:
#  # グローバル設定の名前がmilkeclair、メールがmilkeclair@example.comの場合
#  z.git.user.global
#  # 出力:
#  # --- global user info ---
#  # user.name: milkeclair
#  # user.email: milkeclair@example.com
z.git.user.global() {
  z.io "--- global user info ---"
  local user_name=$(git config --global user.name)
  local user_email=$(git config --global user.email)
  z.io "user.name: $user_name"
  z.io "user.email: $user_email"
}
