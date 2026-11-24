# 呼び出しに使われた参照を有効なインスタンスIDへ解決する。
#
# $1: インスタンス参照
# REPLY: インスタンスID
# return: 0|1
#
# example:
#  z.cls.draw Counter
#  z.cls.drew
#  local counter=""
#  z.cls.new Counter counter
#  z.cls.instance._resolve "$counter"
#  # REPLY: counterと同じインスタンスID
#  # return: 0
z.cls.instance._resolve() {
  if z.is.null "$1" || ! z.var.exists "z_cls_instances[$1]"; then
    z.io.error "Instance reference $1 is not available in this scope."
    return 1
  fi

  if z.var.exists "z_cls_active[$1]" && z.is.not.eq "${z_cls_current_instance-}" "$1"; then
    z.io.error "Instance $1 is active in another instance call."
    return 1
  fi

  REPLY=$1
}
