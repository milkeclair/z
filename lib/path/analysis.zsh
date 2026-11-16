# 現在の作業ディレクトリを取得する
#
# REPLY: 現在の作業ディレクトリのパス
# return: null
#
# example:
#   z.path.current
#   echo $REPLY  # outputs "/home/user"
z.path.current() {
  REPLY=$(pwd)
}

# ホームディレクトリのパスを取得する
#
# REPLY: ホームディレクトリのパス
# return: null
#
# example:
#   z.path.home
#   echo $REPLY  # outputs "/home/username"
z.path.home() {
  REPLY=$HOME
}
