# ztcpのファイルディスクリプタに対応するリモートホストを取得する
#
# $1: ztcpのファイルディスクリプタ
# REPLY: リモートホスト
# return: null
#
# example:
#  z.wtproxy.start._serve.remote.host 12
z.wtproxy.start._serve.remote.host() {
  local target_fd=$1

  for line in "${(@f)$(ztcp -L)}"; do
    # ztcp -Lの行形式: fd type local_host local_port remote_host remote_port
    local words=("${(@)${(z)line}}")
    local fd=$words[1]
    local remote_host=$words[5]

    if z.is.eq $fd $target_fd; then
      REPLY=$remote_host
      return
    fi
  done

  REPLY=""
}
