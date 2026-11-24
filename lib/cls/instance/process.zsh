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

  z.is.not.null "${z_cls_instances[$1]:-}" && z_cls_instance=$1
  z.cls.instance.call._validate "$z_cls_instance" "$2" "$3" "$1" || return 1

  if z.is.eq "$2" method; then
    z.cls.instance.call._run "$z_cls_instance" "$3" "${@:4}"
  else
    z.cls.instance.call._access "$z_cls_instance" "$2" "$3" "${@:4}"
  fi
}

# メソッド本体を、readonlyのselfとメソッド引数を持つ関数スコープで実行する。
#
# $1: 実体の参照
# $2: メソッド名
# $@?: メソッドに渡す引数
# REPLY: メソッドの結果
# return: メソッドの終了コード
#
# example:
#  # 前提: objectがREPLY=$selfを実行するidentityメソッドを持つ
#  z.cls.instance._execute "$object" identity
#  # REPLY: objectと同じ実体参照
#  # return: 0
z.cls.instance._execute() {
  local z_cls_instance=$1
  local z_cls_body=$z_cls_bodies[${z_cls_instances[$1]}:$2]

  shift 2

  # EXITトラップもメソッド引数で動くよう、本体専用のスコープを作る。
  () {
    local -r self=$z_cls_instance

    eval "$z_cls_body"
  } "$@"
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
  if ! z.var.exists "$2"; then
    z_cls_values[$1:$2]="typeset -- $2; unset $2"
    return 0
  fi

  case ${(tP)2} in
    scalar|scalar-local)
      z.cls.store._scalar "$1" "$2" "${(P)2}"
      return 0
      ;;
    integer|integer-local)
      if z.int.is.match "${(P)2}"; then
        z.cls.store._scalar "$1" "$2" "${(P)2}" -i
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
  local class_name=$z_cls_instances[$instance_id]

  z.cls.store._names "${z_cls_members[$instance_id]-}"
  z.cls.instance.commands._uninstall "${REPLY[@]}"

  local attribute

  z.cls.store._names "${z_cls_class_attrs[$class_name]-}"
  for attribute in "${REPLY[@]}"; do
    unset "z_cls_values[$instance_id:$attribute]"
  done

  # 未設定のactive要素も管理ノードを残すため、一緒に削除する。
  unset "z_cls_instances[$instance_id]" "z_cls_members[$instance_id]" "z_cls_active[$instance_id]"
}
