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
  # 再読込前に生成したコマンドも、新しい保存領域を使って属性を更新する。
  if ! z.var.exists z_cls_scalars; then
    z.cls.store._ensure
  fi

  local z_cls_instance=${(P)1:-}

  z.str.start_with "$1" z_cls_ && z_cls_instance=$1
  if z.is.null "$z_cls_instance"; then
    z.io.error "Instance reference $1 is not available in this scope."
    return 1
  fi

  case $2 in
    method) z.cls.instance.call._run "$z_cls_instance" "$3" "${@:4}" ;;
    get) z.cls.instance.call._get "$z_cls_instance" "$3" "${@:4}" ;;
    set) z.cls.instance.call._set "$z_cls_instance" "$3" "${@:4}" ;;
    *) return 1 ;;
  esac
}

# 復元済みの属性を保存する。通常のスカラーは文字列、型付き属性は宣言として保持する。
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
  if ! z.var.exists "$2"; then
    unset "z_cls_scalars[$1:$2]"
    z_cls_values[$1:$2]="typeset -- $2; unset $2"
    return 0
  fi

  case ${(tP)2} in
    scalar|scalar-local)
      z.cls.store._scalar "$1" "$2" "${(P)2}"
      return 0
      ;;
  esac

  unset "z_cls_scalars[$1:$2]"

  case ${(tP)2} in
    integer|integer-local)
      if z.int.is.match "${(P)2}"; then
        z_cls_values[$1:$2]="typeset -i $2=${(P)2}"
        return 0
      fi
      ;;
    array|array-local)
      local -a REPLY=()
      z.arr.quote style=single "${(@P)2}"

      z.arr.join "${REPLY[@]}"
      z_cls_values[$1:$2]="typeset -a $2=( $REPLY )"
      return 0
      ;;
    association|association-local)
      local -a REPLY=()
      z.arr.quote style=single "${(@Pkv)2}"

      z.arr.join "${REPLY[@]}"
      z_cls_values[$1:$2]="typeset -A $2=( $REPLY )"
      return 0
      ;;
  esac

  local declaration=$(typeset -p "$2")

  z_cls_values[$1:$2]=${declaration/#typeset -g /typeset }
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
  local -a REPLY=()
  local instance_id=$1
  local reference=${z_cls_owner_refs[$instance_id]:-$instance_id}
  local class_name=$z_cls_instances[$instance_id]

  unset "z_cls_references[$reference]" "z_cls_owner_refs[$instance_id]"
  z.cls.store._names "${z_cls_members[$instance_id]-}"
  z.cls.instance.commands._uninstall "${REPLY[@]}"

  local attribute

  z.cls.store._names "${z_cls_class_attrs[$class_name]-}"
  for attribute in "${REPLY[@]}"; do
    unset "z_cls_scalars[$instance_id:$attribute]" "z_cls_values[$instance_id:$attribute]"
  done

  # 未設定のactive要素も管理ノードを残すため、一緒に削除する。
  unset "z_cls_instances[$instance_id]" "z_cls_members[$instance_id]" \
    "z_cls_active[$instance_id]" "z_cls_owner_markers[$instance_id]"

  z.hash.count z_cls_instances
  if z.int.is.zero "$REPLY"; then
    # 最後の実体を片付けたら、空のテーブルの容量も解放する。
    z_cls_instances=()
    z_cls_scalars=()
    z_cls_values=()
    z_cls_members=()
    z_cls_active=()
    z_cls_wrapper_refs=()
    z_cls_owner_markers=()
    z_cls_references=()
    z_cls_owner_refs=()
    z_cls_gc_allocations=0
  fi
}
