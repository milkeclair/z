# ファイルの各行を配列へ読み込む
#
# $path: ファイルのパス
# REPLY: 行の配列
# return: null
#
# example:
#  z.file.read.lines path="/path/to/file.txt"
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
#  z.file.read.pick path="/path/to/file.txt" word="search_word"
z.file.read.pick() {
  z.arg.named path $@ && local file=$REPLY
  z.arg.named word $@ && local word=$REPLY

  if z.file.exists $file; then
    REPLY=$(grep $word $file | head -n 1)
  else
    REPLY=""
  fi
}
