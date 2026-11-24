# 呼出しや属性の復元に進む前に、解決済みの処理を検証する。
#
# $1: 解決済みの実体参照
# $2: method、get、setのいずれか
# $3: メンバー名
# $4: エラーに表示する、元の変数名または参照
# REPLY: null
# return: 0|1
#
# example:
#  # 前提: objectは非実行中で、countを持つ実体の参照変数
#  z.cls.instance.call._validate "$object" get count object
#  # return: 0
z.cls.instance.call._validate() {
  local instance_id=$1

  if z.is.null "${z_cls_instances[$instance_id]:-}"; then
    z.io.error "Instance reference $4 is not available in this scope."
    return 1
  fi

  local member_key="${z_cls_instances[$instance_id]}:$3"

  if z.is.eq "$2" method; then
    z.var.exists "z_cls_bodies[$member_key]" || return 1
  else
    z.var.exists "z_cls_defaults[$member_key]" || return 1
  fi

  if z.is.not.null "${z_cls_active[$instance_id]:-}" &&
      z.is.not.eq "${z_cls_current_instance:-}" "$instance_id"; then
    z.io.error "Instance $instance_id is active in another instance call."
    return 1
  fi

  return 0
}

# 保存済みの通常スカラーを直接扱い、それ以外は属性のスコープを復元して処理する。
#
# $1: 実体参照
# $2: getまたはset
# $3: 属性名
# $@?: 取得・更新に渡す引数
# REPLY: 取得・更新の結果
# return: 取得・更新の終了コード
#
# example:
#  # 前提: objectは初期値0のcountを持つ実体の参照変数
#  z.cls.instance.call._access "$object" get count
#  # REPLY: 0
#  # return: 0
z.cls.instance.call._access() {
  local z_cls_instance=$1
  local z_cls_operation=$2
  local z_cls_member=$3
  local z_cls_declaration=$z_cls_values[$1:$3]
  local z_cls_value_type=""

  if z.str.start_with "$z_cls_declaration" "typeset -- $z_cls_member="; then
    z_cls_value_type=scalar
  elif z.str.start_with "$z_cls_declaration" "typeset -i $z_cls_member="; then
    z_cls_value_type=integer
  fi

  shift 3

  case "$z_cls_operation:$z_cls_value_type" in
    get:scalar|get:integer)
      z.int.is.zero $# || return 1

      local z_cls_literal=${z_cls_declaration#*=}

      z.str.unquote "$z_cls_literal"
      return $?
      ;;
    set:scalar)
      z.int.is.eq $# 1 || return 1
      z.cls.store._scalar "$z_cls_instance" "$z_cls_member" "$1"
      return 0
      ;;
    set:integer)
      z.int.is.eq $# 1 || return 1

      if z.int.is.match "$1"; then
        local -i z_cls_numeric=0

        (( z_cls_numeric = $1, 1 )) || return 1

        z.cls.store._scalar "$z_cls_instance" "$z_cls_member" "$z_cls_numeric" -i
        return 0
      fi
      ;;
  esac

  z.cls.instance.call._access_typed "$z_cls_instance" "$z_cls_operation" "$z_cls_member" "$@"
}

# 型付き属性の復元、取得・更新、保存を同じ関数スコープで行う。
#
# $1: 実体参照
# $2: getまたはset
# $3: 属性名
# $@?: 取得・更新に渡す引数
# REPLY: 取得・更新の結果
# return: 取得・更新の終了コード
#
# example:
#  # 前提: objectのitemsは保存済みの添字配列(one "two words")
#  z.cls.instance.call._access_typed "$object" get items
#  # REPLY: ("one" "two words")
#  # return: 0
z.cls.instance.call._access_typed() {
  local z_cls_instance=$1
  local z_cls_operation=$2
  local z_cls_member=$3
  local -a z_cls_attributes=("$z_cls_member")

  shift 3

  if z.is.eq "$z_cls_operation" set; then
    # 数値式は、同じ実体の他の属性を参照できる。
    z_cls_attributes=(${=z_cls_class_attrs[${z_cls_instances[$z_cls_instance]}]})
  fi

  local z_cls_attribute

  for z_cls_attribute in "${z_cls_attributes[@]}"; do
    eval "$z_cls_values[$z_cls_instance:$z_cls_attribute]"
  done

  case $z_cls_operation in
    get)
      z.cls.instance.execute._get "$z_cls_member" "$@"
      ;;
    set)
      z.cls.instance.execute._set "$z_cls_member" "$@" || return $?
      z.cls.instance._snapshot "$z_cls_instance" "$z_cls_member"
      ;;
  esac
}

# メソッドを実行する間、実体の実行中フラグと現在の実体参照を管理する。
#
# $1: 実体参照
# $2: メソッド名
# $@?: メソッドに渡す引数
# REPLY: メソッドの結果
# return: メソッドの終了コード
#
# example:
#  # 前提: objectが$self.count.set 4を実行してreturn 7するfailメソッドを持つ
#  z.cls.instance.call._run "$object" fail
#  # return: 7
#  # 変更後: countは4、実行中フラグは解除済み
z.cls.instance.call._run() {
  local z_cls_instance=$1

  if z.is.not.null "${z_cls_active[$z_cls_instance]:-}"; then
    z.cls.instance._execute "$@"
    return $?
  fi

  local z_cls_current_instance=$z_cls_instance
  local z_cls_result=0

  z_cls_active[$z_cls_instance]=1
  {
    z.cls.instance._execute "$@"
  } always {
    z_cls_result=$?
    unset "z_cls_active[$z_cls_instance]"
  }

  return $z_cls_result
}
