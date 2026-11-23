# 実体が生きている間だけ使える読み取り参照でコールバックを実行する。
#
# $1: 内部の実体ID
# $2: 読み取り参照を第1引数に受け取る関数名
# $@?: コールバックの追加引数
# REPLY: コールバックの結果
# return: コールバックの終了コード
#
# example:
#  # 前提: objectでCounterの実体を作成済み
#  read_value() { $1.count.get }
#  z.cls.borrow._with "$object" read_value
#  # REPLY: 0
z.cls.borrow._with() {
  local z_cls_id=$1
  local z_cls_callback=$2
  shift 2

  local z_cls_ref="z_cls_ref_${$}_$(( ++z_cls_next_reference ))"
  local -a z_cls_commands=()

  () {
    local REPLY=""
    z.cls.instance._commands "$z_cls_instances[$z_cls_id]" "$z_cls_ref" read
    z_cls_commands=("${(@)REPLY}")

    z.cls.instance.commands._validate "${z_cls_commands[@]}" || return 1
    z.cls.instance.commands._install "${z_cls_commands[@]}"
  } || return 1

  z_cls_references[$z_cls_ref]=$z_cls_id
  z_cls_borrow_counts[$z_cls_id]=$(( ${z_cls_borrow_counts[$z_cls_id]:-0} + 1 ))
  local z_cls_result=0
  {
    "$z_cls_callback" "$z_cls_ref" "$@"
  } always {
    z_cls_result=$?
    unset "z_cls_references[$z_cls_ref]"
    z.cls.instance.commands._uninstall "${z_cls_commands[@]}"
    z_cls_borrow_counts[$z_cls_id]=$(( z_cls_borrow_counts[$z_cls_id] - 1 ))
    (( z_cls_borrow_counts[$z_cls_id] )) || unset "z_cls_borrow_counts[$z_cls_id]"
  }

  return $z_cls_result
}
