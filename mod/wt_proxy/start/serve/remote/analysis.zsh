# get remote host for a ztcp file descriptor
#
# $1: ztcp file descriptor
# REPLY: remote host
# return: null
#
# example:
#  z.wt_proxy.start._serve.remote.host 12
z.wt_proxy.start._serve.remote.host() {
  local target_fd=$1

  for line in "${(@f)$(ztcp -L)}"; do
    # ztcp -L line: fd type local_host local_port remote_host remote_port
    local words=("${(@)${(z)line}}")
    local fd=$words[1]
    local remote_host=$words[5]

    if z.is.eq $fd $target_fd; then
      z.return $remote_host
      return
    fi
  done

  z.return
}
