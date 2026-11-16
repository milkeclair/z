# 呼出しや属性の復元に進む前に、解決済みの処理を検証する。
#
# $1: 解決済みの実体参照
# $2: method、get、setのいずれか
# $3: メンバー名
# $4: エラーに表示する、元の変数名または参照
# REPLY: 変更しない
# return: 0|1
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
# $1: 非実行中の実体参照
# $2: getまたはset
# $3: 属性名
# $@?: 取得・更新に渡す引数
# REPLY: 取得・更新の結果
# return: 取得・更新の終了コード
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
      z_cls_values[$z_cls_instance:$z_cls_member]="$z_cls_scalar_prefix${(qq)1}"
      return 0
    fi

    if z.int.is.match "$1"; then
      local -i z_cls_numeric=$1

      z_cls_values[$z_cls_instance:$z_cls_member]="$z_cls_integer_prefix${(qq)z_cls_numeric}"
      return 0
    fi
  fi

  z.cls.instance.call._run "$z_cls_instance" "$z_cls_operation" "$z_cls_member" "$@"
}

# 処理の実行、属性の保存、実行中フラグの解除まで、復元した属性を同じスコープに保つ。
#
# $1: 非実行中の実体参照
# $2: method、get、setのいずれか
# $3: メンバー名
# $@?: 処理に渡す引数
# REPLY: 処理の結果
# return: 処理の終了コード
z.cls.instance.call._run() {
  local z_cls_instance=$1
  local z_cls_operation=$2
  local -a z_cls_attributes=("$3")

  if z.is.not.eq "$z_cls_operation" get; then
    z_cls_attributes=(${=z_cls_class_attrs[${z_cls_instances[$z_cls_instance]}]})
  fi

  local z_cls_attribute

  for z_cls_attribute in "${z_cls_attributes[@]}"; do
    eval "$z_cls_values[$z_cls_instance:$z_cls_attribute]"
  done

  local z_cls_current_instance=$z_cls_instance
  local z_cls_result=0

  z_cls_active[$z_cls_instance]=1
  {
    if z.cls.instance._execute "$@"; then
      z_cls_result=0
    else
      z_cls_result=$?
    fi
  } always {
    if z.is.not.eq "$z_cls_operation" get; then
      for z_cls_attribute in "${z_cls_attributes[@]}"; do
        if ! z.cls.instance._snapshot "$z_cls_instance" "$z_cls_attribute"; then
          z_cls_values[$z_cls_instance:$z_cls_attribute]="$(typeset -p "$z_cls_attribute")"
        fi
      done
    fi

    unset "z_cls_active[$z_cls_instance]"
  }

  return $z_cls_result
}
