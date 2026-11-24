# 呼び出しや属性の復元に進む前に、解決済みの処理を検証する。
#
# $1: 解決済みのインスタンス参照
# $2: method、get、setのいずれか
# $3: メンバー名
# $4: エラーに表示する、元の変数名または参照
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.draw Counter
#    z.cls.attr count default=0
#  z.cls.drew
#  local object=""
#  z.cls.new Counter object
#  z.cls.instance.call._validate "$object" get count object
#  # return: 0
z.cls.instance.call._validate() {
  local instance_id=$1

  if z.is.null "${z_cls_instances[$instance_id]-}"; then
    z.io.error "Instance reference $4 is not available in this scope."
    return 1
  fi

  local member_key="${z_cls_instances[$instance_id]}:$3"

  if z.is.eq "$2" method; then
    z.var.exists "z_cls_bodies[$member_key]" || return
  else
    z.var.exists "z_cls_defaults[$member_key]" || return
  fi

  if z.is.not.null "${z_cls_active[$instance_id]-}" &&
      z.is.not.eq "${z_cls_current_instance-}" "$instance_id"; then
    z.io.error "Instance $instance_id is active in another instance call."
    return 1
  fi

  return 0
}

# 保存済みの通常スカラーを直接扱い、それ以外は属性のスコープを復元して処理する。
#
# $1: インスタンス参照
# $2: getまたはset
# $3: 属性名
# $@?: 取得・更新に渡す引数
# REPLY: 取得・更新の結果
# return: 取得・更新の終了コード
#
# example:
#  z.cls.store._ensure
#  local object=example
#  z_cls_values[example:count]='typeset -i count=0'
#  z.cls.instance.call._access "$object" get count
#  # REPLY: 0
#  # return: 0
z.cls.instance.call._access() {
  if z.str.start_with "$z_cls_values[$1:$3]" "typeset -i $3="; then
    case $2 in
      get)
        z.is.eq "$#" 3 || return 1
        z.str.unquote "${z_cls_values[$1:$3]#*=}"
        return $?
        ;;
      set)
        z.is.eq "$#" 4 || return 1
        if z.int.is.match "$4"; then
          local -i number=0
          (( number = $4, 1 )) || return 1
          z_cls_values[$1:$3]="typeset -i $3=$number"
          return 0
        fi
        ;;
    esac
  elif z.str.start_with "$z_cls_values[$1:$3]" "typeset -- $3="; then
    case $2 in
      get)
        z.is.eq "$#" 3 || return 1
        z.str.unquote "${z_cls_values[$1:$3]#*=}"
        return $?
        ;;
      set)
        z.is.eq "$#" 4 || return 1
        z.cls.store._scalar "$1" "$3" "$4"
        return 0
        ;;
    esac
  fi

  z.cls.instance.call._access_typed "$@"
}

# 型付き属性の復元、取得・更新、保存を同じ関数スコープで行う。
#
# $1: インスタンス参照
# $2: getまたはset
# $3: 属性名
# $@?: 取得・更新に渡す引数
# REPLY: 取得・更新の結果
# return: 取得・更新の終了コード
#
# example:
#  z.cls.store._ensure
#  local object=example
#  z_cls_values[example:items]='typeset -a items=(one "two words")'
#  z.cls.instance.call._access_typed "$object" get items
#  # REPLY: ("one" "two words")
#  # return: 0
z.cls.instance.call._access_typed() {
  local -a z_cls_attributes=("$3")
  if z.is.eq "$2" set; then
    # 数値式から参照できるよう、更新時は同じインスタンスの属性をすべて復元する。
    local -a REPLY=()
    z.cls.store._names "$z_cls_class_attrs[${z_cls_instances[$1]}]"
    z_cls_attributes=("${REPLY[@]}")
  fi

  local z_cls_attribute
  for z_cls_attribute in "${z_cls_attributes[@]}"; do
    eval "$z_cls_values[$1:$z_cls_attribute]"
  done

  local z_cls_member=$3

  case $2 in
    get)
      shift 3
      z.cls.instance.execute._get "$z_cls_member" "$@"
      ;;
    set)
      local z_cls_instance_id=$1
      shift 3
      z.cls.instance.execute._set "$z_cls_member" "$@" || return
      z.cls.instance._snapshot "$z_cls_instance_id" "$z_cls_member"
      ;;
  esac
}

# メソッドを実行する間、インスタンスの実行中フラグと現在のインスタンス参照を管理する。
#
# $1: インスタンス参照
# $2: メソッド名
# $@?: メソッドに渡す引数
# REPLY: メソッドの結果
# return: メソッドの終了コード
#
# example:
#  z.cls.draw Counter
#    z.cls.attr count default=0
#    z.cls.method fail '$self.count.set 4; return 7'
#  z.cls.drew
#  local object=""
#  z.cls.new Counter object
#  z.cls.instance.call._run "$object" fail
#  # return: 7
#  # 変更後: countは4、実行中フラグは解除済み
z.cls.instance.call._run() {
  if z.is.not.null "${z_cls_active[$1]-}"; then
    z.cls.instance._execute "$@"
    return $?
  fi

  local z_cls_current_instance=$1

  z_cls_active[$1]=1
  {
    z.cls.instance._execute "$@"
  } always {
    unset "z_cls_active[$1]"
  }
}
