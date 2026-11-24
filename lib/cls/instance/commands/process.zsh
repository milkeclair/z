# 登録先の名前が空いていることを検証する。
#
# $@: 登録するコマンド名
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.store._ensure
#  z.cls.instance.commands._validate z_cls_12345_1.increment
#  # return: 0
z.cls.instance.commands._validate() {
  local command_name

  for command_name in "$@"; do
    if z.var.exists "aliases[$command_name]" || z.var.exists "galiases[$command_name]" ||
      z.var.exists "functions[$command_name]" || z.var.exists "commands[$command_name]"; then
      z.io.error "Command $command_name already exists."
      return 1
    fi
  done

  return 0
}

# メンバーへの呼び出しを共有するテンプレートとして登録する。
#
# $1: コマンド名の接尾辞
# $member: メソッド名または属性名
# $handler: メンバーへの処理を実行する関数
# REPLY: null
# return: 0
#
# example:
#  z.cls.store._ensure
#  z.cls.instance.commands._template count.get member=count handler=z.cls.instance.call._get
#  # 変更後: z_cls_dispatch_count.get に属性の取得処理を登録済み
z.cls.instance.commands._template() {
  local suffix=$1
  shift

  z.var.exists "z_cls_dispatch_programs[$suffix]" && return 0

  local REPLY=""
  z.arg.named member "$@" && local member=$REPLY
  z.arg.named handler "$@" && local handler=$REPLY

  z.str.quote "$member"
  local template="z_cls_dispatch_$suffix"
  functions[$template]="$handler"' "${funcstack[1]%%.*}" '"$REPLY"' "$@"'
  z_cls_dispatch_programs[$suffix]=$functions[$template]
}

# クラスのメンバーの呼び出しに使うテンプレートを用意する。
#
# $1: 定義中のクラス名
# REPLY: インスタンスのコマンド名に付ける接尾辞の配列
# return: 0
#
# example:
#  z.cls.draw Counter
#    z.cls.attr count default=0
#    z.cls.instance.commands._prepare Counter
#    # REPLY: ("count.get" "count.set")
#  z.cls.drew
z.cls.instance.commands._prepare() {
  local -a suffixes=()
  local member

  z.cls.store._names "$z_cls_class_methods[$1]"
  for member in "${REPLY[@]}"; do
    z.cls.instance.commands._template "$member" "member=$member" handler=z.cls.instance.call._run
    suffixes+=("$member")
  done

  z.cls.store._names "$z_cls_class_attrs[$1]"
  for member in "${REPLY[@]}"; do
    z.cls.instance.commands._template "$member.get" "member=$member" handler=z.cls.instance.call._get
    z.cls.instance.commands._template "$member.set" "member=$member" handler=z.cls.instance.call._set
    suffixes+=("$member.get" "$member.set")
  done

  REPLY=("${suffixes[@]}")
}

# 参照の各コマンドに、クラス公開時に用意した本体を登録する。
#
# $1: インスタンス参照
# $class: 公開済みのクラス名
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.draw Counter
#    z.cls.attr count default=0
#  z.cls.drew
#  z.cls.instance.commands._install example class=Counter
#  # return: 0
#  # 変更後: example.count.get と example.count.set を登録済み
z.cls.instance.commands._install() {
  local reference=$1
  shift

  local -a REPLY=()
  z.arg.named class "$@" && local class_name=$REPLY
  z.cls.store._names "$z_cls_classes[$class_name]"
  local -a suffixes=("${REPLY[@]}")
  local -a names=("${(@)suffixes/#/$reference.}")

  z.cls.instance.commands._validate "${names[@]}" || return

  local -a installed=()
  local suffix
  for suffix in "${suffixes[@]}"; do
    local command_name="$reference.$suffix"
    if ! functions -c "z_cls_dispatch_$suffix" "$command_name"; then
      if z.int.is.not.zero "${#installed}"; then
        unfunction "${installed[@]}"
      fi
      return 1
    fi

    installed+=("$command_name")
  done

  return 0
}

# 参照で使っていたコマンドのうち、登録時の本体を保つものを解除する。
#
# $1: インスタンス参照
# $class: インスタンスのクラス名
# REPLY: null
# return: 0
#
# example:
#  z.cls.draw Counter
#    z.cls.attr count default=0
#  z.cls.drew
#  z.cls.instance.commands._install example class=Counter
#  z.cls.instance.commands._uninstall example class=Counter
#  # 変更後: example.count.get と example.count.set を解除済み
z.cls.instance.commands._uninstall() {
  local reference=$1
  shift

  local -a REPLY=()
  z.arg.named class "$@" && local class_name=$REPLY
  z.cls.store._names "$z_cls_classes[$class_name]"

  local -a names=()
  local suffix
  for suffix in "${REPLY[@]}"; do
    local command_name="$reference.$suffix"
    if z.cls.instance.commands.is._managed "$command_name" "suffix=$suffix"; then
      names+=("$command_name")
    fi
  done

  if z.int.is.not.zero "${#names}"; then
    unfunction "${names[@]}"
  fi
}
