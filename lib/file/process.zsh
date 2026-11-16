# ファイルがなければ作成する
#
# $path: ファイルのパス
# $with_dir?: 親ディレクトリがなければ作成するか（既定: false）
# REPLY: null
# return: null
#
# example:
#  z.file.make path="/path/to/file.txt" with_dir=true
z.file.make() {
  z.arg.named path $@ && local file=$REPLY
  z.arg.named with_dir $@ default=false && local with_dir=$REPLY

  if z.is.true $with_dir; then
    z.dir.make path=$(dirname $file)
  fi

  z.file.not.exists $file && touch $file >/dev/null 2>&1
}

# ファイルへ内容を書き込む（上書き）
#
# $path: ファイルのパス
# $content: 書き込む内容
# $overwrite?: 既存ファイルの置換を許可するか（既定: true）
# REPLY: null
# return: 書き込めた場合は0、それ以外は1
#
# example:
#  z.file.write path="/path/to/file.txt" content="hello world"
z.file.write() {
  z.arg.named path "$@" && local file=$REPLY
  z.arg.named content "$@" && local content=$REPLY
  z.arg.named overwrite "$@" default=true && local overwrite=$REPLY
  z.is.null "$file" && return 1

  setopt localoptions
  if z.is.true $overwrite; then
    setopt clobber
  else
    setopt noclobber
  fi

  print -rn -- "$content" > "$file"
}

# ファイルの内容を読む
#
# $path: ファイルのパス
# REPLY: ファイルの内容
# return: null
#
# example:
#  z.file.read path="/path/to/file.txt"
z.file.read() {
  z.arg.named path $@ && local file=$REPLY

  if z.file.exists $file; then
    REPLY=$(cat $file)
  else
    REPLY=""
  fi
}

