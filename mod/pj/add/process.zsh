# 既存の登録を保持しながらプロジェクトの登録を書き込む
#
# $name: 検証済みのプロジェクト名
# $dir: 正規化したプロジェクトディレクトリの絶対パス
# REPLY: null
# return: 0|1
#
# example:
#  # /tmp/exampleが存在し、同名の登録がない場合
#  z.pj.add._write name=example dir=/tmp/example
#  # return: 0
#  # 結果: exampleの登録ファイルへ/tmp/exampleが保存される
z.pj.add._write() {
  z.arg.named name "$@" && local name=$REPLY
  z.arg.named dir "$@" && local dir=$REPLY
  z.pj.file._path "$name" || return 1
  local file=$REPLY

  if [[ -e $file || -L $file ]]; then
    z.io.error "Project is already registered: $name"
    return 1
  fi

  z.pj.file._root
  local registry=$REPLY
  if z.dir.not.exists "$registry"; then
    z.dir.make path="$registry" || return 1
  fi

  z.file.write path="$file" content="$dir"$'\n' overwrite=false
}
