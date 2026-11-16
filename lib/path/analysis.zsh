# 現在の作業ディレクトリを取得する
#
# REPLY: 現在の作業ディレクトリのパス
# return: null
#
# example:
#  # カレントディレクトリが/tmp/z-exampleの場合
#  z.path.current
#  # REPLY: "/tmp/z-example"
z.path.current() {
  REPLY=$(pwd)
}

# ホームディレクトリのパスを取得する
#
# REPLY: ホームディレクトリのパス
# return: null
#
# example:
#  # HOME=/home/exampleの場合
#  z.path.home
#  # REPLY: "/home/example"
z.path.home() {
  REPLY=$HOME
}
