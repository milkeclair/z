# 現在のシェルでクラス定義を開始する。
# 開始を拒否した定義は、対応するz.cls.drewまで実行を抑止する。
#
# $1: クラス名
# REPLY: null
# return: 0|1
#
# example:
#  # 前提: Counterが未登録で、他のクラスを定義していない
#  z.cls.draw Counter
#  # return: 0
#  # 変更後: Counterを定義中
z.cls.draw() {
  z.cls.store._ensure

  if ! z.int.is.eq $# 1 || ! z.cls.is._name "${1:-}"; then
    z.io.error "Expected a valid class name."
  elif z.is.not.null "$z_cls_drawing" || z.is.not.null "${z_cls_classes[$1]:-}"; then
    z.io.error "Class $1 already exists or a definition is active."
  else
    z_cls_class_attrs[$1]=''
    z_cls_class_methods[$1]=''
    z_cls_drawing=$1
    typeset -g +x z_cls_draw_stack=${(j:|:)funcstack[2,-1]}
    typeset -gi +x z_cls_draw_failed=0

    unsetopt localoptions
    z.cls.capture._watch
    return 0
  fi

  typeset -gi +x z_cls_reject_depth=1 z_cls_reject_method=0
  typeset -g +x z_cls_reject_stack=${(j:|:)funcstack[2,-1]}
  unsetopt localoptions
  z.cls.capture._watch
  return 1
}

# 定義中のクラスにスカラー属性と初期値を登録する。
#
# $1: 属性名
# $default: 空文字列を含む属性の初期値
# REPLY: null
# return: 0|1
#
# example:
#  # 前提: z.cls.draw Counterで定義を開始している
#  z.cls.attr count default=0
#  # return: 0
#  # 変更後: Counterの属性countの初期値は0
z.cls.attr() {
  z.cls.store._ensure

  if (( $# == 2 )) && z.str.start_with "$1" default=; then
    set -- "$2" "$1"
  fi

  if ! z.int.is.eq $# 2 || z.is.null "$z_cls_drawing" || ! z.cls.is._attribute "${1:-}" ||
      ! z.str.start_with "${2:-}" default=; then
    z.io.error "Expected an active class, an ordinary attribute name, and default=."
    [[ -n $z_cls_drawing ]] && z_cls_draw_failed=1
    return 1
  fi

  local key="$z_cls_drawing:$1"

  if z.var.exists "z_cls_defaults[$key]"; then
    z.io.error "Attribute $1 already exists."
    z_cls_draw_failed=1
    return 1
  fi

  z_cls_defaults[$key]=${2#default=}
  z_cls_class_attrs[$z_cls_drawing]+="$1 "
}

# メソッド本体の収集を開始するか、引数で渡された本体を登録する。
# 引用しない本体の末尾には、独立した文としてz.cls.fn.doneを置く。
#
# $1: メソッド名
# $2?: 引数で指定する本体
# REPLY: null
# return: 0|1
#
# example:
#  # 前提: Counterを定義中で、属性countを登録している
#  z.cls.fn increment
#    (( ++count ))
#    REPLY=$count
#  z.cls.fn.done
#  # return: 0
#  # 変更後: Counterにincrementメソッドを登録済み
z.cls.fn() {
  z.cls.store._ensure

  local invalid=0
  local key="$z_cls_drawing:${1:-}"

  if z.int.is.lt $# 1 || z.int.is.gt $# 2 || z.is.null "$z_cls_drawing" || ! z.cls.is._name "${1:-}"; then
    z.io.error "Expected an active class and a valid method name."
    invalid=1
  elif z.var.exists "z_cls_bodies[$key]"; then
    z.io.error "Method $1 already exists."
    invalid=1
  fi

  if z.int.is.gteq $# 2; then
    z.int.is.zero $invalid || return 1
    z_cls_bodies[$key]=$2
    z_cls_class_methods[$z_cls_drawing]+="$1 "
    return 0
  fi

  unsetopt localoptions
  z.cls.capture._start "${1:-invalid}" "${(j:|:)funcstack[2,-1]}" "${funcfiletrace[1]%:*}" "$invalid"
}

# メソッドの収集を終えたクラスを公開する。
# 拒否された定義の終端や属性の登録に失敗した定義では1を返す。
#
# REPLY: null
# return: 0|1
#
# example:
#  # 前提: Counterを定義中で、全メソッドの収集が完了している
#  z.cls.drew
#  # return: 0
#  # 変更後: Counterを公開済み。z.cls.new Counter counterで実体を作れる
z.cls.drew() {
  z.cls.store._ensure

  if (( ${z_cls_reject_result:-0} )); then
    unset z_cls_reject_result
    unsetopt localoptions
    [[ -n $z_cls_drawing ]] || z.cls.capture._stop
    return 1
  fi

  if z.is.null "$z_cls_drawing"; then
    z.io.error "No class definition is active."
    return 1
  fi

  unsetopt localoptions
  if (( z_cls_draw_failed )); then
    z.cls.abort
    return 1
  fi

  z.cls.capture._stop
  z_cls_classes[$z_cls_drawing]=1
  z_cls_drawing=''
}

# 未完了の定義を破棄し、元のDEBUGトラップを復元する。
#
# REPLY: null
# return: 0
#
# example:
#  # 前提: Counterを定義中で、まだ公開していない
#  z.cls.abort
#  # return: 0
#  # 変更後: Counterの未公開定義を破棄し、元のDEBUGトラップを復元済み
z.cls.abort() {
  z.cls.store._ensure
  unsetopt localoptions
  z.cls.capture._stop

  local REPLY=""
  local key

  z.hash.keys z_cls_defaults
  for key in "${(@)REPLY}"; do
    z.str.start_with "$key" "$z_cls_drawing:" && unset "z_cls_defaults[$key]"
  done

  z.hash.keys z_cls_bodies
  for key in "${(@)REPLY}"; do
    z.str.start_with "$key" "$z_cls_drawing:" && unset "z_cls_bodies[$key]"
  done

  if z.is.not.null "$z_cls_drawing"; then
    unset "z_cls_class_attrs[$z_cls_drawing]" "z_cls_class_methods[$z_cls_drawing]"
  fi

  z_cls_drawing=''

  return 0
}

# 独立した実体を作成し、参照をreadonly変数へ代入する。
#
# $1: 公開済みのクラス名
# $2: 実体参照を受け取る変数名。必要に応じて呼出元でlocal宣言する
# REPLY: 実体参照
# return: 0|1
#
# example:
#  # 前提: Counterを公開済み。PIDが12345で、初回の実体作成である場合の例
#  local counter=""
#  z.cls.new Counter counter
#  # return: 0
#  # REPLY: "z_cls_12345_1"
#  # 変更後: counter="z_cls_12345_1"。counterはreadonly
z.cls.new() {
  z.cls.store._ensure

  z.cls.new._validate "$@" || return 1

  local z_cls_class=$1
  local z_cls_binding=$2

  (( ++z_cls_next_id ))

  local z_cls_id="z_cls_${$}_$z_cls_next_id"

  z.cls.instance._commands "$z_cls_class" "$z_cls_binding" "$z_cls_id"

  local -a z_cls_wrappers=("${(@)REPLY}")

  z.cls.instance.commands._validate "${z_cls_wrappers[@]}" || return 1

  local z_cls_member

  for z_cls_member in ${=z_cls_class_attrs[$z_cls_class]}; do
    z.cls.store._scalar "$z_cls_id" "$z_cls_member" "$z_cls_defaults[$z_cls_class:$z_cls_member]"
  done

  z.cls.instance.commands._install "${z_cls_wrappers[@]}"

  z_cls_members[$z_cls_id]="${(j: :)z_cls_wrappers}"
  z_cls_instances[$z_cls_id]=$z_cls_class
  : ${(P)z_cls_binding::=$z_cls_id}
  typeset -gr -- "$z_cls_binding"

  REPLY=$z_cls_id
}

# 実体、生成したコマンド、保存済みの属性を削除する。
#
# $1: 実体の変数名または参照
# REPLY: null
# return: 0|1
#
# example:
#  # 前提: counterが非実行中の実体を参照している
#  z.cls.delete counter
#  # return: 0
#  # 変更後: 実体の状態と生成したコマンドを解放済み。counterの値は維持
z.cls.delete() {
  z.cls.store._ensure

  local REPLY=""

  z.int.is.eq $# 1 || return 1

  local z_cls_id=${(P)1:-}

  z.is.not.null "${z_cls_instances[$1]:-}" && z_cls_id=$1

  if z.is.null "${z_cls_instances[$z_cls_id]:-}" || z.is.not.null "${z_cls_active[$z_cls_id]:-}"; then
    z.io.error "Expected an existing, inactive instance reference."
    return 1
  fi

  z.cls.instance._release "$z_cls_id"

  z.hash.count z_cls_instances
  if z.int.is.zero $REPLY; then
    # 全実体の削除後に空テーブルを作り直し、バケットと未設定ノードを解放する。
    z_cls_instances=()
    z_cls_values=()
    z_cls_members=()
    z_cls_active=()
    z_cls_wrapper_refs=()
  fi

  return 0
}
