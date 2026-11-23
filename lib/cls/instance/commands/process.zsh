# 実体の作成でシェルを変更する前に、生成するコマンド名を検証する。
#
# $@: 生成するコマンド名
# REPLY: null
# return: 全ての名前が利用可能または所有済みなら0、それ以外はエラーを表示して1
#
# example:
#  # 前提: z_cls_12345_1.incrementというコマンドや別名は未登録
#  z.cls.instance.commands._validate z_cls_12345_1.increment
#  # return: 0
z.cls.instance.commands._validate() {
  local REPLY=""
  local z_cls_command

  for z_cls_command in "$@"; do
    if z.var.exists "aliases[$z_cls_command]" || z.var.exists "galiases[$z_cls_command]"; then
      z.io.error "Command $z_cls_command already exists."
      return 1
    fi

    if z.is.not.null "${z_cls_wrapper_refs[$z_cls_command]:-}" &&
        z.cls.instance._owns "$z_cls_command"; then
      continue
    fi

    if z.var.exists "functions[$z_cls_command]" || z.var.exists "commands[$z_cls_command]"; then
      z.io.error "Command $z_cls_command already exists."
      return 1
    fi
  done

  return 0
}

# 共有する呼出し本体を登録し、実体からの参照数を数える。
#
# $@: 検証済みのコマンド名
# REPLY: null
# return: 0
#
# example:
#  # 前提: 保存領域を初期化し、z_cls_12345_1.incrementの名前を検証済み
#  z.cls.instance.commands._install z_cls_12345_1.increment
#  # return: 0
#  # 変更後: z_cls_12345_1.incrementを登録し、参照数は1
z.cls.instance.commands._install() {
  local -a z_cls_installed=()
  local z_cls_command

  for z_cls_command in "$@"; do
    local z_cls_member=${z_cls_command#*.}
    local z_cls_operation=method

    if z.str.includes "$z_cls_member" .; then
      z_cls_operation=${z_cls_member##*.}
      z_cls_member=${z_cls_member%.*}
    fi

    local z_cls_template="z_cls_dispatch_${z_cls_operation}_$z_cls_member"

    if ! z.var.exists "functions[$z_cls_template]"; then
      local z_cls_handler=$z_cls_operation
      z.is.eq "$z_cls_operation" method && z_cls_handler=run

      functions[$z_cls_template]='z.cls.instance.call._'"$z_cls_handler"' "${funcstack[1]%%.*}" '"${(q)z_cls_member}"' "$@"'
      z_cls_dispatch_programs[${z_cls_command#*.}]=$functions[$z_cls_template]
    fi

    if ! functions -c "$z_cls_template" "$z_cls_command"; then
      z.cls.instance.commands._uninstall "${z_cls_installed[@]}"
      return 1
    fi

    z_cls_installed+=("$z_cls_command")
    (( z_cls_wrapper_refs[$z_cls_command] += 1 ))
  done

  return 0
}

# 生成時に登録したコマンドを手放し、置き換えられていない本体を解放する。
#
# $@: 登録済みのコマンド名
# REPLY: null
# return: 0
#
# example:
#  # 前提: z_cls_12345_1.incrementが実体用に1回登録されている
#  z.cls.instance.commands._uninstall z_cls_12345_1.increment
#  # 変更後: z_cls_12345_1.incrementの生成済みコマンドを削除
z.cls.instance.commands._uninstall() {
  local z_cls_command

  for z_cls_command in "$@"; do
    z_cls_wrapper_refs[$z_cls_command]=$(( z_cls_wrapper_refs[$z_cls_command] - 1 ))
    z.int.is.zero $z_cls_wrapper_refs[$z_cls_command] || continue

    if z.cls.instance._owns "$z_cls_command"; then
      unfunction "$z_cls_command"
    fi

    unset "z_cls_wrapper_refs[$z_cls_command]"
  done

  return 0
}
