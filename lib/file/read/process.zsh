# ファイルの各行を配列へ読み込む
#
# $path: ファイルのパス
# REPLY: 行の配列
# return: null
#
# example:
#  # /tmp/z-example.txtにhelloとworldが1行ずつ書かれている場合
#  z.file.read.lines path=/tmp/z-example.txt
#  # REPLY: ("hello" "world")
z.file.read.lines() {
  z.arg.named path $@ && local file=$REPLY

  if z.file.exists $file; then
    REPLY=(${(f)$(cat $file)})
  else
    REPLY=()
  fi
}

# 指定した単語を含む行をファイルから取り出す
#
# $path: ファイルのパス
# $word: 検索する単語
# REPLY: 単語を含む行|null
# return: null
#
# example:
#  # /tmp/z-example.txtにsearch_word hereという行がある場合
#  z.file.read.pick path=/tmp/z-example.txt word=search_word
#  # REPLY: "search_word here"
z.file.read.pick() {
  z.arg.named path $@ && local file=$REPLY
  z.arg.named word $@ && local word=$REPLY

  if z.file.exists $file; then
    REPLY=$(grep $word $file | head -n 1)
  else
    REPLY=""
  fi
}
