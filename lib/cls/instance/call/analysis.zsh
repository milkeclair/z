# インスタンスの属性値またはクラスの初期値を返す。
#
# $1: インスタンス参照
# $2: 属性名
# REPLY: 属性の文字列
# return: 0|1
#
# example:
#  z.cls.draw Counter
#    z.cls.attr count default=0
#  z.cls.drew
#  local counter=""
#  z.cls.new Counter counter
#  $counter.count.get
#  # REPLY: "0"
z.cls.instance.call._get() {
  z.is.eq "$#" 2 || return
  local instance_id=""
  z.cls.instance._resolve "$1" instance_id || return

  local default_key="$z_cls_instances[$instance_id]:$2"
  z.var.exists "z_cls_defaults[$default_key]" || return

  REPLY=${z_cls_scalars[$instance_id:$2]-$z_cls_defaults[$default_key]}
}
