# インスタンスの作成でシェルを変更する前に、生成するコマンド名を検証する。
#
# $@: 生成するコマンド名
# REPLY: null
# return: 全ての名前が利用可能または所有済みなら0、それ以外はエラーを表示して1
#
# example:
#  z.cls.store._ensure
#  z.cls.instance.commands._validate z_cls_12345_1.increment
#  # return: 0
z.cls.instance.commands._validate() {
  local REPLY=""
  local command_name

  for command_name in "$@"; do
    if z.var.exists "aliases[$command_name]" || z.var.exists "galiases[$command_name]"; then
      z.io.error "Command $command_name already exists."
      return 1
    fi

    if z.is.not.null "${z_cls_wrapper_refs[$command_name]-}" &&
        z.cls.instance.commands.is._managed "$command_name"; then
      continue
    fi

    if z.var.exists "functions[$command_name]" || z.var.exists "commands[$command_name]"; then
      z.io.error "Command $command_name already exists."
      return 1
    fi
  done

  return 0
}

# コマンド名を検証し、共有する呼び出し本体を登録する。
#
# $@: 検証済みのコマンド名
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.store._ensure
#  z.cls.instance.commands._install z_cls_12345_1.increment
#  # return: 0
#  # 変更後: z_cls_12345_1.incrementを登録し、参照数は1
z.cls.instance.commands._install() {
  local -a REPLY=()
  z.cls.instance.commands._validate "$@" || return

  local -a installed_commands=()
  local command_name

  for command_name in "$@"; do
    local suffix=${command_name#*.}
    local template="z_cls_dispatch_$suffix"

    if ! z.var.exists "functions[$template]"; then
      z.arr.split delimiter=. "$suffix"
      local member=$REPLY[1]
      local operation=${REPLY[2]:-method}

      local handler=z.cls.instance.call._$operation
      z.is.eq "$operation" method && handler=z.cls.instance.call._run

      functions[$template]="$handler"' "${funcstack[1]%%.*}" '"${(q)member}"' "$@"'
      z_cls_dispatch_programs[$suffix]=$functions[$template]
    fi

    if ! functions -c "$template" "$command_name"; then
      z.cls.instance.commands._uninstall "${installed_commands[@]}"
      return 1
    fi

    installed_commands+=("$command_name")
    (( z_cls_wrapper_refs[$command_name] += 1 ))
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
#  z.cls.store._ensure
#  z.cls.instance.commands._install z_cls_12345_1.increment
#  z.cls.instance.commands._uninstall z_cls_12345_1.increment
#  # 変更後: z_cls_12345_1.incrementの生成済みコマンドを削除
z.cls.instance.commands._uninstall() {
  local REPLY=""
  local command_name

  for command_name in "$@"; do
    z_cls_wrapper_refs[$command_name]=$(( z_cls_wrapper_refs[$command_name] - 1 ))
    z.int.is.zero $z_cls_wrapper_refs[$command_name] || continue

    if z.cls.instance.commands.is._managed "$command_name"; then
      unfunction "$command_name"
    fi

    unset "z_cls_wrapper_refs[$command_name]"
  done

  return 0
}
