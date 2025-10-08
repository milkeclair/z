# Available commands:
#  c, continue
#  p <var>
#  h, help
#  q, quit, exit
#
# example:
#   z.debug
z.debug() {
  local _saved_reply=$REPLY
  [[ $Z_DEBUG -eq 1 ]] && return 0

  print -- "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  print -- "👀: ${funcfiletrace}"
  print -- "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local continue=0

  while [[ $continue -eq 0 ]]; do
    print -n -- "z> "
    read -r response
    local debug_command=${response%% *}
    local debug_args=${response#* }

    case $debug_command in
    c|continue)
      continue=1
      ;;
    p|print)
      if [[ -n $debug_args ]]; then
        local var_name=$debug_args
        if [[ $var_name == "REPLY" || $var_name == "reply" ]]; then
          print -- $_saved_reply
        elif [[ -n $(typeset -p $var_name 2>/dev/null) ]]; then
          print -- ${(P)var_name}
        else
          print -- "❌: '$var_name' not found"
        fi
      else
        print -- "❌: p <variable_name>"
      fi
      ;;
    h|help|"")
      print -- "Available commands:"
      print -- "  c, continue"
      print -- "  p <var>"
      print -- "  h, help"
      print -- "  q, quit, exit"
      ;;
    q|quit|exit)
      exit 1
      ;;
    *)
      [[ -n $debug_command ]] && eval "$debug_command $debug_args"
      ;;
    esac
  done

  REPLY=$_saved_reply
  print -- ""
}

z.debug.enable() {
  Z_DEBUG=0
}

z.debug.disable() {
  Z_DEBUG=1
}
