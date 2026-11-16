# 指定した接頭辞でコマンドを実行する対話モード。
#
# $split?: 接頭辞とコマンドの間に挿入する文字列（既定: " "）
# $@: 接頭辞となるコマンドとその引数
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
