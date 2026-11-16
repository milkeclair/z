# クラス・実体・属性・メソッドの識別子を検証する。
#
# $1: 識別子
# REPLY: null
# return: 0|1
z.cls.is._name() {
  local name=${1:-}
  local pattern='^[A-Za-z_][A-Za-z0-9_]*$'

  z.str.is.match "$name" "$pattern" &&
    ! z.str.start_with "$name" z_cls_
}

# 通常のローカル変数として復元できる属性名を検証する。
#
# $1: 属性名
# REPLY: null
# return: 0|1
z.cls.is._attribute() {
  z.cls.is._name "${1:-}" &&
    z.is.not.eq "$1" REPLY &&
    z.is.not.eq "$1" reply &&
    z.str.excludes "${parameters[$1]:-}" special
}
