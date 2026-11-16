# ディレクトリがなければ作成する
#
# $path: ディレクトリのパス
# REPLY: null
# return: null
#
# example:
#  z.dir.make path=/tmp/z-example
#  z.dir.exists /tmp/z-example
#  # return: 0
z.dir.make() {
  z.arg.named path $@ && local dir=$REPLY

  z.dir.not.exists $dir && mkdir -p $dir
}

# ディレクトリが存在すれば削除する
#
# $path: ディレクトリのパス
# REPLY: null
# return: null
#
# example:
#  # /tmp/z-exampleが存在する場合
#  z.dir.remove path=/tmp/z-example
#  z.dir.not.exists /tmp/z-example
#  # return: 0
z.dir.remove() {
  z.arg.named path $@ && local dir=$REPLY

  z.dir.exists $dir && rm -rf $dir
}
