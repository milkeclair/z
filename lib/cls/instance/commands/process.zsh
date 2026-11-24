# 実体の作成でシェルを変更する前に、生成するコマンド名を検証する。
#
# $@: 生成するコマンド名
# REPLY: null
# return: 全ての名前が利用可能または所有済みなら0、それ以外はエラーを表示して1
#
# example:
#  # 前提: counter.incrementというコマンドや別名は未登録
#  z.cls.instance.commands._validate counter.increment
#  # return: 0
z.cls.instance.commands._validate() {
  local REPLY=""
  local command_name

  for command_name in "$@"; do
    if z.var.exists "aliases[$command_name]" || z.var.exists "galiases[$command_name]"; then
      z.io.error "Command $command_name already exists."
      return 1
    fi

    if z.is.not.null "${z_cls_wrapper_refs[$command_name]:-}" &&
        z.cls.instance._owns "$command_name"; then
      continue
    fi

    if z.var.exists "functions[$command_name]" || z.var.exists "commands[$command_name]"; then
      z.io.error "Command $command_name already exists."
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
#  # 前提: 保存領域を初期化し、counter.incrementの名前を検証済み
#  z.cls.instance.commands._install counter.increment
#  # return: 0
#  # 変更後: counter.incrementを登録し、参照数は1
z.cls.instance.commands._install() {
  local command_name

  for command_name in "$@"; do
    local member=${command_name#*.}
    local operation=method

    if z.str.includes "$member" .; then
      operation=${member##*.}
      member=${member%.*}
    fi

    local template="z_cls_dispatch_${operation}_$member"

    if ! z.var.exists "functions[$template]"; then
      functions[$template]='z.cls.instance._call "${funcstack[1]%%.*}" '"$operation ${(q)member}"' "$@"'
      z_cls_dispatch_programs[${command_name#*.}]=$functions[$template]
    fi

    functions -c "$template" "$command_name"
    (( z_cls_wrapper_refs[$command_name] += 1 ))
  done

  return 0
}
