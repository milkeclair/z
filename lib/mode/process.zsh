# 指定した接頭辞でコマンドを実行する対話モード。
#
# $split?: 接頭辞とコマンドの間に挿入する文字列（既定: " "）
# $@: 接頭辞となるコマンドとその引数
# REPLY: null
# return: null
#
# example:
#  z.mode git split=" "
#  # 入力例: status
#  # 実行されるコマンド: git status
#  # 続けてexitを入力した場合
#  # return: 1
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
