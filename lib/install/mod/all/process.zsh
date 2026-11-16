# 配布対象の全modの導入または置換を確認する
#
# $dir: 導入済みmodのディレクトリ
# REPLY: null
# return: y/Yなら0、それ以外は1
#
# example:
#  # 確認にyを入力した場合
#  z.install.mod.all._confirm dir=~/.z/mod
#  # return: 0
z.install.mod.all._confirm() {
  z.arg.named dir "$@" && local dir=$REPLY

  z.io.oneline "Install or update all available mods in $dir? (y/n): "
  z.io.read || return 1
  local answer=$REPLY

  if z.is.eq "$answer" y || z.is.eq "$answer" Y; then
    REPLY=""
    return 0
  fi

  REPLY=""
  return 1
}

# ローカルだけのmodデータを保持しながら、配布対象の全modを準備する
#
# $source: 配布対象modのディレクトリ
# $current: 導入済みmodのディレクトリ。存在しない場合もある
# $dir: 新しく準備したmodディレクトリ
# REPLY: null
# return: 0|1
#
# example:
#  # ソースと作業先が有効で、準備に成功した場合
#  z.install.mod.all._prepare source=/tmp/source/mod current=~/.z/mod dir=/tmp/next
#  # return: 0
#  # 結果: /tmp/nextへ導入用のmod一式が用意される
z.install.mod.all._prepare() {
  z.arg.named source "$@" && local source_dir=$REPLY
  z.arg.named current "$@" && local current_dir=$REPLY
  z.arg.named dir "$@" && local dir=$REPLY

  z.dir.exists "$source_dir" || return 1
  cp -R "$source_dir/." "$dir" || return 1

  if z.dir.exists "$current_dir"; then
    for entry in "$current_dir"/*(ND); do
      local name=${entry:t}

      if z.dir.exists "$entry" && z.dir.exists "$source_dir/$name"; then
        continue
      fi

      cp -R "$entry" "$dir/" || return 1
    done
  fi

  REPLY=""
}

# 準備したmodを配置先へ切り替え、失敗時は元のディレクトリに戻す
#
# $current: 導入済みmodのディレクトリ。存在しない場合もある
# $prepared: 準備済みのmodディレクトリ
# $backup: 未使用のバックアップ先パス
# REPLY: null
# return: 0|1
#
# example:
#  # preparedが用意され、backupが未使用の場合
#  z.install.mod.all._replace current=~/.z/mod prepared=/tmp/next backup=/tmp/previous
#  # return: 0
#  # 結果: ~/.z/modが/tmp/nextの内容へ切り替わる
z.install.mod.all._replace() {
  z.arg.named current "$@" && local current_dir=$REPLY
  z.arg.named prepared "$@" && local prepared=$REPLY
  z.arg.named backup "$@" && local backup=$REPLY

  z.dir.exists "$prepared" || return 1
  z.dir.exists "$backup" && return 1

  if z.dir.exists "$current_dir"; then
    mv "$current_dir" "$backup" || return 1
  fi

  if ! mv "$prepared" "$current_dir"; then
    if z.dir.exists "$backup"; then
      mv "$backup" "$current_dir" || z.io.error "restore mods from $backup"
    fi
    return 1
  fi

  REPLY=""
}

# 作業ディレクトリに接続し直し、新しく導入したmodを読み込む
# 補完の設定は再読み込み結果に影響しない
#
# $dir: 読み込み済みのzのインストール先
# $previous?: 切り替え前の作業ディレクトリ（既定: PWD）
# REPLY: null
# return: 0|1
#
# example:
#  # dirに有効なインストール先がある場合
#  z.install.mod.all._reload dir=~/.z previous=$PWD
#  # return: 0
#  # 結果: 新しいmodの関数が現在のシェルへ読み込まれる
z.install.mod.all._reload() {
  z.arg.named dir "$@" && local dir=$REPLY
  z.arg.named previous "$@" default="$PWD" && local previous_dir=$REPLY
  z.is.null "$dir" && return 1

  local mod_dir="$dir/mod"
  if z.is.eq "$previous_dir" "$mod_dir" || z.str.start_with "$previous_dir" "$mod_dir/"; then
    z.str.remove.prefix "$previous_dir" "$mod_dir"
    local relative_dir=$REPLY

    cd "$mod_dir$relative_dir" 2>/dev/null || cd "$dir" || return 1
  fi

  export Z_ROOT="$dir"
  source "$dir/main.zsh" || return 1

  if (( ${+functions[z.completion.enable]} )); then
    z.completion.enable
  fi

  REPLY=""
}
