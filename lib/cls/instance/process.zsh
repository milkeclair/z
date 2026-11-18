# 実体の参照からメソッドまたは属性への操作を呼び出す。
#
# $1: 実体の変数名または参照
# $2: method、get、setのいずれか
# $3: メソッド名または属性名
# $@?: 処理に渡す引数
# REPLY: 処理の結果
# return: 処理の終了コード
#
# example:
#  # 前提: objectは初期値0のcountとincrementを持つCounterの参照変数
#  z.cls.instance._call object method increment
#  # REPLY: 1
#  # return: 0
z.cls.instance._call() {
  local z_cls_instance=${(P)1:-}
  local z_cls_operation=$2
  local z_cls_member=$3

  z.is.not.null "${z_cls_instances[$1]:-}" && z_cls_instance=$1
  z.cls.instance.call._validate "$z_cls_instance" "$z_cls_operation" "$z_cls_member" "$1" || return 1

  shift 3

  if z.is.eq "$z_cls_operation" method; then
    z.cls.instance.call._run "$z_cls_instance" "$z_cls_operation" "$z_cls_member" "$@"
  else
    z.cls.instance.call._access "$z_cls_instance" "$z_cls_operation" "$z_cls_member" "$@"
  fi
}

# メソッドにreadonlyのselfと引数を渡すか、復元済みの属性を取得・更新する。
#
# $1: 実体の参照
# $2: method、get、setのいずれか
# $3: メソッド名または属性名
# $@?: 処理に渡す引数
# REPLY: 処理の結果
# return: 処理の終了コード
#
# example:
#  # 前提: 呼出元でlocal count=4を宣言している
#  z.cls.instance._execute unused get count
#  # REPLY: 4
#  # return: 0
z.cls.instance._execute() {
  local z_cls_instance=$1
  local z_cls_operation=$2
  local z_cls_member=$3

  shift 3

  case $z_cls_operation in
    method)
      local z_cls_body=$z_cls_bodies[${z_cls_instances[$z_cls_instance]}:$z_cls_member]

      # EXITトラップもメソッド引数で動くよう、本体専用のスコープを作る。
      () {
        local -r self=$z_cls_instance

        eval "$z_cls_body"
      } "$@"
      ;;
    get)
      z.cls.instance.execute._get "$z_cls_member" "$@"
      ;;
    set)
      z.cls.instance.execute._set "$z_cls_member" "$@"
      ;;
  esac
}

# 復元済みの属性を、同じ型で再作成できる宣言として保存する。
# 通常の値はパラメータ展開を使い、特殊な属性フラグだけtypesetで取得する。
#
# $1: 実体参照
# $2: 属性名
# REPLY: null
# return: 0
#
# example:
#  # 前提: 呼出元でlocal -i 16 number=255を宣言している
#  z.cls.instance._snapshot object number
#  # return: 0
#  # 変更後: z_cls_values[object:number]に基数16を保つ宣言を保存済み
z.cls.instance._snapshot() {
  local z_cls_snapshot_key="$1:$2"
  local z_cls_snapshot_name=$2

  if ! z.var.exists "$z_cls_snapshot_name"; then
    z_cls_values[$z_cls_snapshot_key]="typeset -- $z_cls_snapshot_name; unset $z_cls_snapshot_name"
    return 0
  fi

  local z_cls_snapshot_type=${(tP)z_cls_snapshot_name}

  case $z_cls_snapshot_type in
    scalar|scalar-local)
      local z_cls_snapshot_value=${(P)z_cls_snapshot_name}

      z.cls.store._scalar "$1" "$z_cls_snapshot_name" "$z_cls_snapshot_value"
      return 0
      ;;
    integer|integer-local)
      local z_cls_snapshot_value=${(P)z_cls_snapshot_name}

      if z.int.is.match "$z_cls_snapshot_value"; then
        z.cls.store._scalar "$1" "$z_cls_snapshot_name" "$z_cls_snapshot_value" -i
        return 0
      fi

      ;;
    array|array-local)
      local -a z_cls_snapshot_values=("${(@P)z_cls_snapshot_name}")

      z_cls_values[$z_cls_snapshot_key]="typeset -a $z_cls_snapshot_name=( ${(j: :)${(@qq)z_cls_snapshot_values}} )"
      return 0
      ;;
    association|association-local)
      local -a z_cls_snapshot_values=("${(@Pkv)z_cls_snapshot_name}")

      z_cls_values[$z_cls_snapshot_key]="typeset -A $z_cls_snapshot_name=( ${(j: :)${(@qq)z_cls_snapshot_values}} )"
      return 0
      ;;
  esac

  local z_cls_snapshot_declaration="$(typeset -p "$z_cls_snapshot_name")"

  z_cls_values[$z_cls_snapshot_key]=${z_cls_snapshot_declaration/#typeset -g /typeset }
}

# 検証済みの実体について、生成したコマンドと保存済みの属性を解放する。
#
# $1: 存在する非実行中の実体参照
# REPLY: null
# return: 0
#
# example:
#  # 前提: objectは非実行中のCounterの実体参照
#  z.cls.instance._release "$object"
#  # return: 0
#  # 変更後: 実体と、参照がなくなった生成コマンドを解放済み
z.cls.instance._release() {
  local z_cls_id=$1
  local z_cls_command

  for z_cls_command in ${=z_cls_members[$z_cls_id]}; do
    z_cls_wrapper_refs[$z_cls_command]=$(( z_cls_wrapper_refs[$z_cls_command] - 1 ))

    z.int.is.zero $z_cls_wrapper_refs[$z_cls_command] || continue

    if z.cls.instance._owns "$z_cls_command"; then
      unfunction "$z_cls_command"
    fi

    unset "z_cls_wrapper_refs[$z_cls_command]"
  done

  local z_cls_attribute

  for z_cls_attribute in ${=z_cls_class_attrs[${z_cls_instances[$z_cls_id]}]}; do
    unset "z_cls_values[$z_cls_id:$z_cls_attribute]"
  done

  # 未設定のactive要素も管理ノードを残すため、一緒に削除する。
  unset "z_cls_instances[$z_cls_id]" "z_cls_members[$z_cls_id]" "z_cls_active[$z_cls_id]"
}
