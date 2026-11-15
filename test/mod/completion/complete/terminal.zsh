if [[ "$1" == initialize ]]; then
  z_mode=normal
  source "$Z_ROOT/main.zsh" || return 1
  cd "$Z_ROOT" || return 1
  stty cols 120 rows 40
  PROMPT=""
  RPROMPT=""
  bindkey -e
  autoload -Uz compinit
  compinit -D

  # first real function used as a completion candidate
  z.fixture.alpha() { :; }

  # second real function used as a completion candidate
  z.fixture.beta() { :; }

  z.completion.cache.build._names
  z.completion.compdef._register || return 1
  z.completion.compdef._register || return 1

  # run the real completion system and report its match and display counts
  z92_complete() {
    _main_complete
    print -r -- "Z92_RESULT:${compstate[nmatches]}:${compstate[list_lines]}:Z92_END"
  }
  zle -C z92-complete complete-word z92_complete
  bindkey '^I' z92-complete

  # clear the input after reporting it so the next case starts at an empty prompt
  z92_buffer() {
    print -r -- "Z92_BUFFER:${BUFFER}:Z92_END"
    BUFFER=""
    CURSOR=0
  }
  zle -N z92-buffer z92_buffer
  bindkey '^X^X' z92-buffer
  return 0
fi

# start the real completion terminal shared by this test file
#
# REPLY: terminal file descriptor
# return: 0|1
z92_terminal_start() {
  zmodload zsh/zpty || return 1
  zmodload zsh/zselect || return 1
  zmodload zsh/datetime || return 1
  zpty -b completion_terminal env TERM=xterm z_mode=normal zsh -dfi || return 1
  local terminal_fd=$REPLY

  zpty -w completion_terminal 'source "$Z_ROOT/test/mod/completion/complete/terminal.zsh" initialize; print Z92_READY'
  z92_terminal_read "$terminal_fd" $'\r\nZ92_READY\r\n' || return 1

  REPLY=$terminal_fd
}

# read terminal output until a marker arrives within five seconds
#
# $1: terminal file descriptor
# $2: marker
# REPLY: terminal output including the marker
# return: 0|1
z92_terminal_read() {
  local terminal_fd=$1
  local marker=$2
  local deadline=$((EPOCHREALTIME + 5))
  local output=""
  local chunk=""

  while [[ "$output" != *"$marker"* ]]; do
    local -i remaining=$(((deadline - EPOCHREALTIME) * 100))
    if (( remaining <= 0 )) || ! zpty -t completion_terminal ||
      ! zselect -r "$terminal_fd" -t "$remaining"; then
      z.io.error "completion terminal timed out: $output"
      return 1
    fi

    while zpty -rt completion_terminal chunk; do
      output+=$chunk
    done
  done

  REPLY=$output
}

# complete one input using isolated aliases, styles and command search paths
#
# $1: terminal file descriptor
# $input: command line to complete
# $setup?: shell commands to prepare this case
# $command_path?: external command fixture directory
# REPLY: null
# return: 0|1
z92_terminal() {
  local terminal_fd=$1
  shift
  z.arg.named input "$@" && local input=$REPLY
  z.arg.named setup "$@" && local setup=$REPLY
  z.arg.named command_path "$@" && local command_path=$REPLY
  local result=""
  local buffer=""
  local prepare="PATH=${(q)command_path}
    hash -r
    unalias z.fixture.alias fixture-command 2>/dev/null
    zstyle -d ':completion:*:z-functions' ignored-patterns
    $setup
    print Z92_READY"

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
      completion) result=${${output##*Z92_RESULT:}%%:Z92_END*} ;;
      buffer) buffer=${${output##*Z92_BUFFER:}%%:Z92_END*} ;;
    esac
  done

  print -r -- "matches:lines=$result"
  print -r -- "buffer=$buffer"
}
