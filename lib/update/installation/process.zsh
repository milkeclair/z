# 準備したディレクトリでインストール先を置換し、切り替え失敗時は元に戻す
#
# $dir: インストール先ディレクトリ
# $prepared: 準備済みのディレクトリ
# $backup: 未使用のバックアップ先パス
# REPLY: null
# return: 0|1
#
# example:
#  # dirとpreparedが存在し、backupが未使用の場合
#  z.update.installation._replace dir=/tmp/z-example prepared=/tmp/next backup=/tmp/previous
#  # return: 0
#  # 結果: /tmp/z-exampleが/tmp/nextの内容に置き換わる
z.update.installation._replace() {
  z.arg.named dir "$@"
  local dir=$REPLY

  z.arg.named prepared "$@"
  local prepared=$REPLY

  z.arg.named backup "$@"
  local backup=$REPLY

  z.is.null "$backup" && return 1
  z.dir.exists "$dir" || return 1
  z.dir.exists "$prepared" || return 1
  z.is.eq "$dir" "$prepared" && return 1
  z.file.exists "$backup" && return 1
  z.dir.exists "$backup" && return 1

  mv "$dir" "$backup" || return 1

  if ! mv "$prepared" "$dir"; then
    mv "$backup" "$dir" || z.io.error "restore the installation from $backup"
    return 1
  fi

  REPLY=""
}

# 更新済みのインストール先を現在のシェルで読み直す
#
# $dir: インストール先ディレクトリ
# $previous?: 置換前の作業ディレクトリ（既定: PWD）
# REPLY: null
# return: 0|1
#
# example:
#  # 新しいインストール先の読み込みが成功する場合
#  z.update.installation._reload dir=~/.z previous=$PWD
#  # return: 0
#  # REPLY: ""
z.update.installation._reload() {
  z.arg.named dir "$@"
  local dir=$REPLY
  z.file.exists "$dir/main.zsh" || return 1

  z.arg.named previous "$@" default="$PWD"
  local previous_dir=$REPLY

  if (( ${+functions[z.completion.cache._cancel]} )); then
    z.completion.cache._cancel
  fi

  if z.is.eq "$previous_dir" "$dir" || z.str.start_with "$previous_dir" "$dir/"; then
    z.str.remove.prefix "$previous_dir" "$dir"
    local relative_dir=$REPLY

    cd "$dir$relative_dir" 2>/dev/null || cd "$dir" || return 1
  fi

  export Z_ROOT="$dir"
  source "$dir/main.zsh" || return 1

  if (( ${+functions[z.completion.enable]} )); then
    z.completion.enable || return 1
  fi

  REPLY=""
}
