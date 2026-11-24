# 現在のシェルでクラス定義を開始する。
# 開始を拒否した定義は、対応するz.cls.drewまで実行を抑止する。
#
# $1: クラス名
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.draw Counter
#  # return: 0
#  z.cls.drew
z.cls.draw() {
  z.cls.store._ensure

  if z.int.is.not.eq "$#" 1 || ! z.cls.is._name "$1"; then
    z.io.error "Expected a valid class name."
  elif z.is.not.null "$z_cls_drawing" || z.var.exists "z_cls_classes[$1]"; then
    z.io.error "Class $1 already exists or a definition is active."
  else
    z_cls_class_attrs[$1]=''
    z_cls_class_methods[$1]=''
    z_cls_drawing=$1
    typeset -g z_cls_draw_stack=${(j:|:)funcstack[2,-1]}
    typeset -gi z_cls_draw_failed=0

    unsetopt localoptions
    z.cls.capture._watch
    return 0
  fi

  typeset -gi z_cls_reject_depth=1 z_cls_reject_method=0
  typeset -g z_cls_reject_stack=${(j:|:)funcstack[2,-1]}

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
#  z.cls.draw Counter
#    z.cls.attr count default=0
#    # return: 0
#  z.cls.drew
z.cls.attr() {
  z.cls.store._ensure

  if z.is.null "$z_cls_drawing"; then
    z.io.error "No class definition is active."
    return 1
  fi

  local REPLY=""
  local -a input_args=("$@")
  local -A parsed_named=([default]="")
  local -a parsed_args=()

  z.arg.parse input=input_args named=parsed_named rest=parsed_args
  z.arr.count "${parsed_args[@]}"

  # 指定されたdefault=を数え、省略や重複と区別する。
  if z.int.is.not.eq "$#" 2 || z.int.is.not.eq "$REPLY" 1; then
    z.io.error "Expected an attribute name and one default= argument."
    z_cls_draw_failed=1
    return 1
  fi

  local attribute=$parsed_args[1]

  if ! z.cls.is._attribute "$attribute"; then
    z.io.error "Expected an ordinary attribute name: $attribute"
    z_cls_draw_failed=1
    return 1
  fi

  local key="$z_cls_drawing:$attribute"

  if z.hash.has.key z_cls_defaults "key=$key"; then
    z.io.error "Attribute $attribute already exists."
    z_cls_draw_failed=1
    return 1
  fi

  z_cls_defaults[$key]=${parsed_named[default]}
  z_cls_class_attrs[$z_cls_drawing]+="$attribute "
}

# メソッド本体の収集を開始するか、引数で渡された本体を登録する。
# 引用しない本体の末尾には、独立した文としてz.cls.method.definedを置く。
#
# $1: メソッド名
# $2? [code]: 引数で指定する本体
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.draw Counter
#    z.cls.attr count default=0
#
#    z.cls.method increment
#      # return: 0
#      $self.count.get
#      $self.count.set "$(( REPLY + 1 ))"
#      $self.count.get
#    z.cls.method.defined
#  z.cls.drew
z.cls.method() {
  z.cls.store._ensure

  local invalid=0

  if z.int.is.zero "$#" || z.int.is.gt "$#" 2; then
    z.io.error "Expected a method name and at most one body."
    invalid=1
  elif z.is.null "$z_cls_drawing"; then
    z.io.error "No class definition is active."
    invalid=1
  elif ! z.cls.is._name "$1"; then
    z.io.error "Expected a valid method name."
    invalid=1
  elif z.var.exists "z_cls_bodies[$z_cls_drawing:$1]"; then
    z.io.error "Method $1 already exists."
    invalid=1
  fi

  if z.int.is.gteq "$#" 2; then
    z.int.is.zero "$invalid" || return 1

    z.cls.store._method "$1" class="$z_cls_drawing" body="$2"
    return 0
  fi

  # 不正な見出しの本体も、終了マーカーまでは収集して実行を止める。
  local method_name=invalid
  z.int.is.zero "$invalid" && method_name=$1

  unsetopt localoptions
  z.cls.capture._start "$method_name" \
    stack="${(j:|:)funcstack[2,-1]}" \
    file="${funcfiletrace[1]%:*}" \
    discard="$invalid"
}

# メソッドの収集を終えたクラスを公開する。
# 拒否された定義の終端や属性の登録に失敗した定義では1を返す。
#
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.draw Counter
#    z.cls.attr count default=0
#  z.cls.drew
#  # return: 0
z.cls.drew() {
  z.cls.store._ensure

  if z.var.exists z_cls_reject_result; then
    unset z_cls_reject_result
    unsetopt localoptions

    if z.is.null "$z_cls_drawing"; then
      z.cls.capture._stop
    fi

    return 1
  fi

  if z.is.null "$z_cls_drawing"; then
    z.io.error "No class definition is active."
    return 1
  fi

  unsetopt localoptions

  if z.int.is.not.zero "$z_cls_draw_failed"; then
    z.cls.abort
    return 1
  fi

  local -a REPLY=()
  z.cls.instance.commands._prepare "$z_cls_drawing"
  z.arr.join "${REPLY[@]}"
  z_cls_classes[$z_cls_drawing]=$REPLY

  z.cls.capture._stop
  z_cls_drawing=''
}

# 未完了の定義を破棄し、元のDEBUGトラップを復元する。
#
# REPLY: null
# return: 0
#
# example:
#  z.cls.draw Counter
#    z.cls.attr count default=0
#  z.cls.abort
#  # return: 0
#  # 変更後: Counterの未公開定義を破棄し、元のDEBUGトラップを復元済み
z.cls.abort() {
  z.cls.store._ensure

  if z.is.not.null "$z_cls_drawing"; then
    z.cls.store._discard "$z_cls_drawing"
    z_cls_drawing=''
  fi

  unsetopt localoptions
  z.cls.capture._stop
}

# 独立したインスタンスを作成し、参照をreadonly変数へ代入する。
#
# $1: 公開済みのクラス名
# $2: インスタンス参照を受け取る、呼び出し元で宣言済みの変数名
# REPLY: インスタンス参照
# return: 0|1
#
# example:
#  z.cls.draw Counter
#  z.cls.drew
#  local counter=""
#  z.cls.new Counter counter
#  # return: 0
#  # REPLY: "z_cls_12345_1"
#  # 変更後: counter="z_cls_12345_1"。counterはreadonly
z.cls.new() {
  z.cls.store._ensure

  z.cls.new._validate "$@" || return

  (( ++z_cls_next_id ))

  local z_cls_id="z_cls_${$}_$z_cls_next_id"

  z.cls.instance.commands._install "$z_cls_id" "class=$1" || return

  z_cls_instances[$z_cls_id]=$1
  : ${(P)2::=$z_cls_id}
  typeset -gr -- "$2"

  REPLY=$z_cls_id
}

# インスタンス、生成したコマンド、保存済みの属性を削除する。
#
# $1: インスタンスの変数名または参照
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.draw Counter
#  z.cls.drew
#  local counter=""
#  z.cls.new Counter counter
#  z.cls.delete counter
#  # return: 0
#  # 変更後: インスタンスの状態と生成したコマンドを解放済み。counterの値は維持
z.cls.delete() {
  z.cls.store._ensure

  local REPLY=""

  z.is.not.eq "$#" 1 && return 1

  if z.str.start_with "$1" z_cls_; then
    local reference=$1
  else
    z.var.get "$1"
    local reference=$REPLY[1]
  fi

  z.cls.instance._resolve "$reference" || return
  local instance_id=$REPLY

  if z.var.exists "z_cls_active[$instance_id]"; then
    z.io.error "Expected an inactive instance reference."
    return 1
  fi

  z.cls.instance._release "$instance_id"
}
