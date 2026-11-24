# コマンドが登録時の本体を保っているか判定する。
#
# $1: 生成したコマンド名
# $suffix: クラスが公開した接尾辞
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.draw Counter
#    z.cls.attr count default=0
#  z.cls.drew
#  z.cls.instance.commands._install example class=Counter
#  z.cls.instance.commands.is._managed example.count.get suffix=count.get
#  # return: 0
z.cls.instance.commands.is._managed() {
  local command_name=$1
  shift

  local REPLY=""
  z.arg.named suffix "$@" && local suffix=$REPLY
  if ! z.var.exists "functions[$command_name]"; then
    return 1
  fi

  # 関数本体に含まれる角括弧などを文字列として比較する。
  setopt localoptions noglobsubst
  z.is.eq "$functions[$command_name]" "$z_cls_dispatch_programs[$suffix]"
}
