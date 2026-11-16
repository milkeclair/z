# ztcpのファイルディスクリプタに対応するリモートホストを取得する
#
# $1: ztcpのファイルディスクリプタ
# REPLY: リモートホスト
# return: null
#
# example:
#  # ztcp -LでFD12の接続先が127.0.0.1と報告される場合
#  z.wtproxy.start._serve.remote.host 12
#  # REPLY: "127.0.0.1"
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
