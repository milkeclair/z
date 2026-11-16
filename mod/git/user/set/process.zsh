# Gitのローカルなユーザー名とメールアドレスを設定する
#
# $1: user.nameの値
# $2: user.emailの値
# REPLY: null
# return: null
#
# example:
#  # 書き込み可能なGitリポジトリ内の場合
#  z.git.user.set "milkeclair" "milkeclair@example.com"
#  # 変更後のローカル設定: user.name=milkeclair、user.email=milkeclair@example.com
z.git.user.set() {
  z.git.user.set.local "$1" "$2"
}

# Gitのローカルなユーザー名とメールアドレスを設定する
#
# $1: user.nameの値
# $2: user.emailの値
# REPLY: null
# return: 0|1
#
# example:
#  # 書き込み可能なGitリポジトリ内の場合
#  z.git.user.set.local "milkeclair" "milkeclair@example.com"
#  # return: 0
#  # 変更後のローカル設定: user.name=milkeclair、user.email=milkeclair@example.com
z.git.user.set.local() {
  z.io "--- set local user info ---"
  z.git.user.set._arg.is.enough "$1" "$2" || return 1

  git config --local user.name "$1" || return 1
  git config --local user.email "$2" || return 1
  z.io "set user.name: $1"
  z.io "set user.email: $2"
}

# Gitのグローバルなユーザー名とメールアドレスを設定する
#
# $1: user.nameの値
# $2: user.emailの値
# REPLY: null
# return: null
#
# example:
#  # グローバル設定へ書き込める場合
#  z.git.user.set.global "milkeclair" "milkeclair@example.com"
#  # 変更後のグローバル設定: user.name=milkeclair、user.email=milkeclair@example.com
z.git.user.set.global() {
  z.io "--- set global user info ---"
  z.git.user.set._arg.is.enough "$1" "$2" || return 1

  git config --global user.name "$1"
  git config --global user.email "$2"
  z.io "set user.name: $1"
  z.io "set user.email: $2"
}
