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
  z.is_false $Z_DEBUG && return 0

  z.io "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  z.io "👀: ${funcfiletrace}"
  z.io "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local continue=0

  while z.int.eq $continue 0; do
    z.io.oneline "z> "
    read -r debug_command debug_args

    case $debug_command in
      c|continue)
        continue=1
        ;;
      p|print)
        if z.is_not_null $debug_args; then
          local var_name=$debug_args

          if z.eq $var_name "REPLY" || z.eq $var_name "reply"; then
            z.io $_saved_reply
          elif z.io.null typeset -p $var_name; then
            z.io ${(P)var_name}
          else
            z.io "❌: '$var_name' not found"
          fi
        else
          z.io "❌: p <variable_name>"
        fi
        ;;
      h|help|"")
        z.io "Available commands:"
        z.io "  c, continue"
        z.io "  p <var>"
        z.io "  h, help"
        z.io "  q, quit, exit"
        ;;
      q|quit|exit)
        exit 1
        ;;
      *)
        z.is_not_null $debug_command && eval "$debug_command $debug_args"
        ;;
    esac
  done

  z.return $_saved_reply
  z.io.empty
}

z.debug.enable() {
  Z_DEBUG=0
}

z.debug.disable() {
  Z_DEBUG=1
}
