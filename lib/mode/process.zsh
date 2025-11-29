# Interactive mode for executing commands with a given prefix.
#
# $split?: string to insert between prefix and command (default: " ")
# $@: prefix command and its arguments
# REPLY: null
# return: null
#
# example:
#  z.mode git split=" "   # starts a REPL where commands are executed as "git <command>"
z.mode() {
  local REPLY

  z.arg.named split $@ default=" "
  local split=$REPLY
  z.arg.named.shift split $@

  local prefix="$REPLY"

  while; do
    z.io.oneline "${prefix}> "
    z.io.read
    local command=$REPLY

    case $command in
    q|quit|exit)
      return 1
      ;;
    *)
      eval "$prefix$split$command"
      ;;
    esac
  done
}
