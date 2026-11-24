# インスタンスの属性へ文字列を保存する。
#
# $1: インスタンス参照
# $2: 属性名
# $3: 空文字列を含む新しい値
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.draw Counter
#    z.cls.attr count default=0
#  z.cls.drew
#  local counter=""
#  z.cls.new Counter counter
#  $counter.count.set 5
#  # return: 0
#  $counter.count.get
#  # REPLY: "5"
z.cls.instance.call._set() {
  z.is.eq "$#" 3 || return

  local instance_id=""
  z.cls.instance._resolve "$1" instance_id || return

  z.var.exists "z_cls_defaults[$z_cls_instances[$instance_id]:$2]" || return
  z_cls_scalars[$instance_id:$2]=$3
}

# メソッドの実行中にselfを渡し、終了時に実行中フラグを解放する。
#
# $1: インスタンス参照
# $2: メソッド名
# $@?: メソッドに渡す引数
# REPLY: メソッドの結果
# return: メソッドの終了コード
#
# example:
#  z.cls.draw Counter
#    z.cls.method fail 'REPLY=reason; return 7'
#  z.cls.drew
#  local counter=""
#  z.cls.new Counter counter
#  $counter.fail
#  # return: 7
#  # REPLY: reason
z.cls.instance.call._run() {
  local z_cls_instance=""
  z.cls.instance._resolve "$1" z_cls_instance || return

  local z_cls_method_key="$z_cls_instances[$z_cls_instance]:$2"
  z.var.exists "z_cls_bodies[$z_cls_method_key]" || return
  local z_cls_body=$z_cls_bodies[$z_cls_method_key]

  local z_cls_self=$1
  shift 2

  local z_cls_activated=false
  if z.is.not.eq "${z_cls_current_instance-}" "$z_cls_instance"; then
    local z_cls_current_instance=$z_cls_instance
    z_cls_active[$z_cls_instance]=1
    z_cls_activated=true
  fi

  {
    # EXITトラップには本体と同じ引数を渡す。
    () {
      local -r self=$z_cls_self

      eval "$z_cls_body"
    } "$@"
  } always {
    if z.is.true "$z_cls_activated"; then
      unset "z_cls_active[$z_cls_instance]"
    fi
  }
}
