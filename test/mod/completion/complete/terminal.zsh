z_mode=normal
source "$Z_ROOT/main.zsh" || exit 1

if z.is.eq "$1" initialize; then
  cd "$Z_ROOT" || return 1
  stty cols 120 rows 40
  PROMPT=""
  RPROMPT=""
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

  # report the buffer after the completion widget has inserted its result
  z92_buffer() {
    print -r -- "Z92_BUFFER:${BUFFER}:Z92_END"
  }
  zle -N z92-buffer z92_buffer
  bindkey '^X' z92-buffer
  return 0
fi

z.arg.named input "$@"
local input=$REPLY

z.arg.named setup "$@"
local setup=$REPLY
zmodload zsh/zpty || exit 1
zmodload zsh/zselect || exit 1

zpty -b completion_terminal env TERM=xterm z_mode=test zsh -dfi || exit 1
{
  local initialization='source "$Z_ROOT/test/mod/completion/complete/terminal.zsh" initialize'
  local result=""
  local buffer=""

  for phase in initialization completion buffer; do
    case $phase in
      initialization)
        zpty -w completion_terminal "$initialization; $setup; print Z92_READY"
        local marker=$'\r\nZ92_READY\r\n'
        ;;
      completion)
        zpty -w -n completion_terminal "$input"$'\t'
        local marker=:Z92_END
        ;;
      buffer)
        zpty -w -n completion_terminal $'\x18'
        local marker=:Z92_END
        ;;
    esac

    local output=""
    local chunk=""
    local matched=false
    for attempt in {1..500}; do
      while zpty -rt completion_terminal chunk; do
        output+=$chunk
      done
      if z.str.includes "$output" "$marker"; then
        matched=true
        break
      fi
      zselect -t 1
    done
    if z.is.false $matched; then
      z.io.error "completion terminal timed out during $phase: $output"
      exit 1
    fi

    case $phase in
      completion) result=${${output##*Z92_RESULT:}%%:Z92_END*} ;;
      buffer) buffer=${${output##*Z92_BUFFER:}%%:Z92_END*} ;;
    esac
  done

  print -r -- "matches:lines=$result"
  print -r -- "buffer=$buffer"
} always {
  zpty -d completion_terminal
}
