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
#  # 前提: 保存領域を初期化し、counter.incrementの名前を検証済み
#  z.cls.instance.commands._install counter.increment
#  # return: 0
#  # 変更後: counter.incrementを登録し、参照数は1
z.cls.instance.commands._install() {
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
      functions[$z_cls_template]='z.cls.instance._call "${funcstack[1]%%.*}" '"$z_cls_operation ${(q)z_cls_member}"' "$@"'
      z_cls_dispatch_programs[${z_cls_command#*.}]=$functions[$z_cls_template]
    fi

    functions -c "$z_cls_template" "$z_cls_command"
    (( z_cls_wrapper_refs[$z_cls_command] += 1 ))
  done

  return 0
}
