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
  local z_cls_instance=$1

  if z.is.null "${z_cls_instances[$z_cls_instance]:-}"; then
    z.io.error "Instance reference $4 is not available in this scope."
    return 1
  fi

  local z_cls_key="${z_cls_instances[$z_cls_instance]}:$3"

  if z.is.eq "$2" method; then
    z.var.exists "z_cls_bodies[$z_cls_key]" || return 1
  else
    z.var.exists "z_cls_defaults[$z_cls_key]" || return 1
  fi

  if z.is.not.null "${z_cls_active[$z_cls_instance]:-}" &&
      z.is.not.eq "${z_cls_current_instance:-}" "$z_cls_instance"; then
    z.io.error "Instance $z_cls_instance is active in another instance call."
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
  local z_cls_scalar_prefix="typeset -- $3="
  local z_cls_integer_prefix="typeset -i $3="

  shift 3

  if z.str.start_with "$z_cls_declaration" "$z_cls_scalar_prefix" ||
      z.str.start_with "$z_cls_declaration" "$z_cls_integer_prefix"; then
    if z.is.eq "$z_cls_operation" get; then
      z.int.is.zero $# || return 1

      local z_cls_literal=${z_cls_declaration#*=}

      REPLY=${(Q)z_cls_literal}
      return 0
    fi

    z.int.is.eq $# 1 || return 1

    if z.str.start_with "$z_cls_declaration" "$z_cls_scalar_prefix"; then
      z.cls.store._scalar "$z_cls_instance" "$z_cls_member" "$1"
      return 0
    fi

    if z.int.is.match "$1"; then
      local -i z_cls_numeric=0

      (( z_cls_numeric = $1, 1 )) || return 1

      z.cls.store._scalar "$z_cls_instance" "$z_cls_member" "$z_cls_numeric" -i
      return 0
    fi
  fi

  z.cls.instance.call._run "$z_cls_instance" "$z_cls_operation" "$z_cls_member" "$@"
}

# メソッドの実行中フラグを管理する。属性操作では、保管している型と値を一時的に復元する。
#
# $1: 実体参照
# $2: method、get、setのいずれか
# $3: メンバー名
# $@?: 処理に渡す引数
# REPLY: 処理の結果
# return: 処理の終了コード
#
# example:
#  # 前提: objectが$self.count.set 4を実行してreturn 7するfailメソッドを持つ
#  z.cls.instance.call._run "$object" method fail
#  # return: 7
#  # 変更後: countは4、実行中フラグは解除済み
z.cls.instance.call._run() {
  local z_cls_instance=$1
  local z_cls_operation=$2

  if z.is.eq "$z_cls_operation" method; then
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
  fi

  local -a z_cls_attributes=("$3")

  if z.is.eq "$z_cls_operation" set; then
    # 数値式は、同じ実体の他の属性を参照できる。
    z_cls_attributes=(${=z_cls_class_attrs[${z_cls_instances[$z_cls_instance]}]})
  fi

  local z_cls_attribute

  for z_cls_attribute in "${z_cls_attributes[@]}"; do
    eval "$z_cls_values[$z_cls_instance:$z_cls_attribute]"
  done

  z.cls.instance._execute "$@" || return $?

  if z.is.eq "$z_cls_operation" set; then
    z.cls.instance._snapshot "$z_cls_instance" "$3"
  fi

  return 0
}
