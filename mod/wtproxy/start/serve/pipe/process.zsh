# pipe data between two TCP file descriptors
#
# $1: left file descriptor
# $2: right file descriptor
# REPLY: null
# return: null
#
# example:
#  z.wtproxy.start._serve.pipe.pair 11 12
z.wtproxy.start._serve.pipe.pair() {
  local left_fd=$1
  local right_fd=$2

  zmodload zsh/zselect
  zmodload zsh/system

  # close left and right conns
  trap "z.io.null ztcp -c $left_fd; z.io.null ztcp -c $right_fd; exit 0" INT TERM EXIT

  while true; do
    local -A ready=()
    zselect -A ready $left_fd $right_fd || return

    for fd in ${(k)ready}; do
      local out_fd=$right_fd
      z.is.eq $fd $right_fd && out_fd=$left_fd

      # サイズは8kbだが、適当なので変えてもいい
      sysread -i $fd -o $out_fd -s 8192
      local exit_status=$?
      case $exit_status in
        0)
          ;;
        *)
          return
          ;;
      esac
    done
  done
}
