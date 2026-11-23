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
  }

  local -a z_cls_installed=()
  local z_cls_command z_cls_suffix z_cls_template z_cls_program
  local z_cls_entered=0
  local z_cls_result=0
  {
    # 一時参照のIDは毎回新しく、各コマンドを1回だけ登録する。
    for z_cls_command in "${z_cls_commands[@]}"; do
      if (( ${+aliases[$z_cls_command]} || ${+galiases[$z_cls_command]} ||
            ${+functions[$z_cls_command]} || ${+commands[$z_cls_command]} )); then
        z.io.error "Command $z_cls_command already exists."
        return 1
      fi

      z_cls_suffix=${z_cls_command#*.}
      case $z_cls_suffix in
        *.get) z_cls_template="z_cls_dispatch_get_${z_cls_suffix%.get}" ;;
        *)     z_cls_template="z_cls_dispatch_method_$z_cls_suffix" ;;
      esac

      builtin functions -c "$z_cls_template" "$z_cls_command" || return 1
      z_cls_installed+=("$z_cls_command")
    done

    z_cls_references[$z_cls_ref]=$z_cls_id
    z_cls_borrow_counts[$z_cls_id]=$(( ${z_cls_borrow_counts[$z_cls_id]:-0} + 1 ))
    z_cls_entered=1
    "$z_cls_callback" "$z_cls_ref" "$@"
  } always {
    z_cls_result=$?
    if (( z_cls_entered )); then
      unset "z_cls_references[$z_cls_ref]"
      z_cls_borrow_counts[$z_cls_id]=$(( z_cls_borrow_counts[$z_cls_id] - 1 ))
      (( z_cls_borrow_counts[$z_cls_id] )) || unset "z_cls_borrow_counts[$z_cls_id]"
    fi

    for z_cls_command in "${z_cls_installed[@]}"; do
      z_cls_suffix=${z_cls_command#*.}
      z_cls_program=${functions[$z_cls_command]-}

      if [[ -n $z_cls_program && $z_cls_program == "${z_cls_dispatch_programs[$z_cls_suffix]-}" ]]; then
        builtin unfunction "$z_cls_command"
      fi
    done
  }

  return $z_cls_result
}
