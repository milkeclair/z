# 既存の作業ディレクトリへブランチのアーカイブを1つダウンロードする
#
# $dir: 作業ディレクトリ
# $branch?: ブランチ名（既定: main）
# REPLY: アーカイブファイルのパス
# return: 0|1
#
# example:
#  z.update.archive._download dir=/tmp/update branch=main
z.update.archive._download() {
  z.arg.named dir "$@"
  local dir=$REPLY
  z.dir.exists "$dir" || { REPLY=""; return 1; }

  z.arg.named branch "$@" default=main
  local branch=$REPLY

  local file="$dir/source.tar.gz"
  z.file.exists "$file" && { REPLY=""; return 1; }

  local url="https://github.com/milkeclair/z/archive/refs/heads/$branch.tar.gz"
  if ! curl -fLsS "$url" -o "$file"; then
    rm -f "$file"
    REPLY=""
    return 1
  fi

  REPLY="$file"
}

# ブランチのアーカイブを新しいディレクトリへ展開する
#
# $file: アーカイブファイル
# $dir: 新しい展開先ディレクトリ
# REPLY: 取り出したソースディレクトリ
# return: 0|1
#
# example:
#  z.update.archive._extract file=/tmp/source.tar.gz dir=/tmp/update/source
z.update.archive._extract() {
  z.arg.named file "$@"

  local file=$REPLY

  z.arg.named dir "$@"
  local dir=$REPLY
  z.is.null "$dir" && { REPLY=""; return 1; }

  z.dir.exists "$dir" && { REPLY=""; return 1; }

  z.dir.make path="$dir" || return 1

  if ! tar -xzf "$file" -C "$dir"; then
    z.dir.remove path="$dir"
    REPLY=""
    return 1
  fi

  local roots=("$dir"/*(N/))
  if ! z.int.is.eq ${#roots} 1; then
    z.dir.remove path="$dir"
    REPLY=""
    return 1
  fi

  REPLY="$roots[1]"
}
