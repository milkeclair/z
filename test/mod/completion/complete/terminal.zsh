if z.is.eq "$1" initialize; then
  z_mode=normal
  cd "$Z_ROOT" || return 1
  stty cols 120 rows 40
  PROMPT=""
  RPROMPT=""
  bindkey -e
  autoload -Uz compinit
  compinit -D

  source "$Z_ROOT/test/mod/completion/complete/fixture.zsh"
  z.completion.cache.build.docs._from_file "$Z_ROOT/test/mod/completion/complete/fixture.zsh"
  z.completion.cache.build.docs._from_file "$Z_ROOT/lib/t/mock.zsh"
  z.completion.cache.build._names
  z.completion.compdef._register || return 1
  z.completion.compdef._register || return 1

  # 実際の補完処理を実行し、一致件数と表示件数を報告する
  z92_complete() {
    _main_complete
    z.io "Z92_RESULT:${compstate[nmatches]}:${compstate[list_lines]}:Z92_END"
  }
  zle -C z92-complete complete-word z92_complete
  bindkey '^I' z92-complete

  # バッファの文字列をそのまま報告し、次のケースのために入力を消去する
  z92_buffer() {
    print -r -- "Z92_BUFFER:${BUFFER}:Z92_END"
    BUFFER=""
    CURSOR=0
  }
  zle -N z92-buffer z92_buffer
  bindkey '^X^X' z92-buffer
  return 0
fi

# このテストファイルで共有する実際の補完端末を起動する
#
# REPLY: 端末のファイルディスクリプタ
# return: 0|1
z92_terminal_start() {
  zmodload zsh/zpty || return 1
  zmodload zsh/zselect || return 1
  zmodload zsh/datetime || return 1
  zpty -b completion_terminal env TERM=xterm z_mode=normal zsh -dfi || return 1
  local terminal_fd=$REPLY

  zpty -w completion_terminal 'source "$Z_ROOT/main.zsh" && source "$Z_ROOT/test/mod/completion/complete/terminal.zsh" initialize && z.io Z92_READY'
  z92_terminal_read "$terminal_fd" $'\r\nZ92_READY\r\n' || return 1

  REPLY="$terminal_fd"
}

# 5秒以内に目印が届くまで端末の出力を読む
#
# $1: 端末のファイルディスクリプタ
# $2: 目印
# REPLY: 目印を含む端末の出力
# return: 0|1
z92_terminal_read() {
  local terminal_fd=$1
  local marker=$2
  local deadline=$((EPOCHREALTIME + 5))
  local output=""
  local chunk=""

  while z.str.excludes "$output" "$marker"; do
    local -i remaining=$(((deadline - EPOCHREALTIME) * 100))
    if z.int.is.lteq "$remaining" 0 || ! zpty -t completion_terminal ||
      ! zselect -r "$terminal_fd" -t "$remaining"; then
      z.io.error "completion terminal timed out: $output"
      return 1
    fi

    while zpty -rt completion_terminal chunk; do
      output+=$chunk
    done
  done

  REPLY="$output"
}

# 別名・スタイル・コマンド検索パスを隔離して、1つの入力を補完する
#
# $1: 端末のファイルディスクリプタ
# $input: 補完するコマンド行
# $setup?: このケースを準備するシェルコマンド
# $command_path?: 外部コマンドのテスト用ディレクトリ
# $display?: 補完画面の出力を結果へ含めるか
# $wait_for?: バッファを読む前に待つ表示文字列
# REPLY: null
# return: 0|1
z92_terminal() {
  local terminal_fd=$1
  shift
  z.arg.named input "$@" && local input=$REPLY
  z.arg.named setup "$@" && local setup=$REPLY
  z.arg.named command_path "$@" && local command_path=$REPLY
  z.arg.named display "$@" default=false && local display=$REPLY
  z.arg.named wait_for "$@" && local wait_for=$REPLY
  local completion_display=""
  local result=""
  local buffer=""
  local prepare="PATH=${(q)command_path}; hash -r; "
  prepare+="unsetopt complete_in_word; "
  prepare+="unalias z.fixture.alias fixture-command 2>/dev/null; "
  prepare+="zstyle -d ':completion:*' ignored-patterns; "
  prepare+="zstyle -d ':completion:*:z-functions' ignored-patterns"
  prepare+=$'\n'"$setup"$'\n'"z.io Z92_READY"

  local phase=""
  for phase in preparation completion buffer; do
    case $phase in
      preparation)
        zpty -w completion_terminal "$prepare"
        local marker=$'\r\nZ92_READY\r\n'
        ;;
      completion)
        zpty -w -n completion_terminal "$input"$'\t'
        local marker=:Z92_END
        ;;
      buffer)
        zpty -w -n completion_terminal $'\x18\x18'
        local marker=:Z92_END
        ;;
    esac

    z92_terminal_read "$terminal_fd" "$marker" || return 1
    local output=$REPLY

    case $phase in
      completion)
        if z.is.not.null "$wait_for" && z.str.excludes "$output" "$wait_for"; then
          z92_terminal_read "$terminal_fd" "$wait_for" || return 1
          output+=$REPLY
        fi
        completion_display=$output
        z.str.partition "$output" Z92_RESULT:
        z.str.partition "$REPLY[2]" :Z92_END
        result=$REPLY[1]
        ;;
      buffer)
        z.str.partition "$output" Z92_BUFFER:
        z.str.partition "$REPLY[2]" :Z92_END
        buffer=$REPLY[1]
        ;;
    esac
  done

  z.io "matches:lines=$result"
  print -r -- "buffer=$buffer"
  if z.is.true "$display"; then
    print -r -- "display=$completion_display"
  fi
}
