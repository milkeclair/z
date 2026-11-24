# 生存中の実体かを確認し、他の実体の呼び出しからの再入を拒否する。
#
# $1: 解決済みの実体参照
# $2?: 呼び出しに使った参照
# REPLY: null
# return: 0|1
#
# example:
#  # 前提: objectは非実行中で、countを持つ実体の参照変数
#  z.cls.instance.call._validate "$object"
#  # return: 0
z.cls.instance.call._validate() {
  local instance_id=$1
  local reference=${2:-$1}
  local owner_reference=${z_cls_owner_refs[$instance_id]:-$instance_id}
  local owner_marker=${z_cls_owner_markers[$instance_id]-}

  if [[ -z ${z_cls_instances[$instance_id]-} || -z $owner_marker ]] ||
      (( ! ${+parameters[$owner_marker]} )) ||
      [[ $owner_reference != "$reference" ]]; then
    z.io.error "Instance reference $reference is not available in this scope."
    return 1
  fi

  if z.is.not.null "${z_cls_active[$instance_id]:-}" &&
      z.is.not.eq "${z_cls_current_instance:-}" "$instance_id"; then
    z.io.error "Instance $instance_id is active in another instance call."
    return 1
  fi

  return 0
}

# 実体IDから属性を更新する。
#
# $1: 実体参照
# $2: 属性名
# $@?: 新しい値または配列の要素
# REPLY: null
# return: 0|1
#
# example:
#  # 前提: objectはlabelを持つ実体の参照変数
#  z.cls.instance.call._set "$object" label hello
#  # return: 0
#  # 変更後: labelの値はhello
z.cls.instance.call._set() {
  local z_cls_id=${z_cls_references[$1]:-$1}
  z.cls.instance.call._validate "$z_cls_id" "$1" || return 1

  if (( ${+z_cls_values[$z_cls_id:$2]} )); then
    z.cls.instance.call._access "$z_cls_id" set "$2" "${@:3}"
    return $?
  fi

  z.is.eq "$#" 3 || return 1

  local default_key="${z_cls_instances[$z_cls_id]}:$2"
  (( ${+z_cls_defaults[$default_key]} )) || return 1

  z_cls_scalars[$z_cls_id:$2]=$3
}

# 十進整数は保存形式から直接処理し、他の宣言は属性を復元して処理する。
#
# $1: 実体参照
# $2: getまたはset
# $3: 属性名
# $@?: 取得・更新に渡す引数
# REPLY: 取得・更新の結果
# return: 取得・更新の終了コード
#
# example:
#  # 前提: objectはcountを十進整数の0として保存している実体の参照変数
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
  fi

  z.cls.instance.call._access_typed "$@"
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
  local -a z_cls_attributes=("$3")
  if z.is.eq "$2" set; then
    # 数値式から参照できるよう、更新時は同じ実体の属性をすべて復元する。
    z_cls_attributes=(${=z_cls_class_attrs[${z_cls_instances[$1]}]})
  fi

  local z_cls_attribute
  for z_cls_attribute in "${z_cls_attributes[@]}"; do
    if z.var.exists "z_cls_values[$1:$z_cls_attribute]"; then
      eval "$z_cls_values[$1:$z_cls_attribute]"
    else
      local -- "$z_cls_attribute=${z_cls_scalars[$1:$z_cls_attribute]-$z_cls_defaults[${z_cls_instances[$1]}:$z_cls_attribute]}"
    fi
  done

  case $2 in
    get)
      z.cls.instance.execute._get "$3" "${@:4}"
      ;;
    set)
      z.cls.instance.execute._set "$3" "${@:4}" || return $?
      z.cls.instance._snapshot "$1" "$3"
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
  local z_cls_instance=${z_cls_references[$1]:-$1}

  z.cls.instance.call._validate "$z_cls_instance" "$1" || return 1
  (( ${+z_cls_bodies[${z_cls_instances[$z_cls_instance]}:$2]} )) || return 1

  local z_cls_body=$z_cls_bodies[${z_cls_instances[$z_cls_instance]}:$2]
  local z_cls_activated=0
  if [[ -z ${z_cls_active[$z_cls_instance]-} ]]; then
    local z_cls_current_instance=$z_cls_instance
    z_cls_active[$z_cls_instance]=1
    z_cls_activated=1
  fi

  local z_cls_self=$1
  shift 2

  {
    # EXITトラップは呼出元の引数を参照するため、内部引数を除いてから本体を実行する。
    () {
      local -r self=$z_cls_self

      eval "$z_cls_body"
    } "$@"
  } always {
    if (( z_cls_activated )); then
      unset "z_cls_active[$z_cls_instance]"
    fi
  }
}
