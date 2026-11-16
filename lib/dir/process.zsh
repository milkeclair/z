# ディレクトリがなければ作成する
#
# $path: ディレクトリのパス
# REPLY: null
# return: null
#
# example:
#  z.dir.make path="/path/to/dir"
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
#  z.dir.remove path="/path/to/dir"
z.dir.remove() {
  z.arg.named path $@ && local dir=$REPLY

  z.dir.exists $dir && rm -rf $dir
}
