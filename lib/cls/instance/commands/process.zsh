# 実体の作成でシェルを変更する前に、生成するコマンド名を検証する。
#
# $@: 生成するコマンド名
# REPLY: 変更しない
# return: 全ての名前が利用可能または所有済みなら0、それ以外はエラーを表示して1
z.cls.instance.commands._validate() {
  local REPLY=""
  local z_cls_member

  for z_cls_member in "$@"; do
    if z.var.exists "aliases[$z_cls_member]" || z.var.exists "galiases[$z_cls_member]"; then
      z.io.error "Command $z_cls_member already exists."
      return 1
    fi

    if z.is.not.null "${z_cls_wrapper_refs[$z_cls_member]:-}" &&
        z.cls.instance._owns "$z_cls_member"; then
      continue
    fi

    if z.var.exists "functions[$z_cls_member]" || z.var.exists "commands[$z_cls_member]"; then
      z.io.error "Command $z_cls_member already exists."
      return 1
    fi
  done

  return 0
}

# 共有する呼出し本体を登録し、実体からの参照数を数える。
#
# $@: 検証済みのコマンド名
# REPLY: 変更しない
# return: 0
z.cls.instance.commands._install() {
  local z_cls_member

  for z_cls_member in "$@"; do
    local z_cls_name=${z_cls_member#*.}
    local z_cls_operation=method

    if z.str.includes "$z_cls_name" .; then
      z_cls_operation=${z_cls_name##*.}
      z_cls_name=${z_cls_name%.*}
    fi

    local z_cls_template="z_cls_dispatch_${z_cls_operation}_$z_cls_name"

    if ! z.var.exists "functions[$z_cls_template]"; then
      functions[$z_cls_template]='z.cls.instance._call "${funcstack[1]%%.*}" '"$z_cls_operation ${(q)z_cls_name}"' "$@"'
      z_cls_dispatch_programs[${z_cls_member#*.}]=$functions[$z_cls_template]
    fi

    functions -c "$z_cls_template" "$z_cls_member"
    unset "z_cls_wrapper_bodies[$z_cls_member]"
    (( z_cls_wrapper_refs[$z_cls_member] += 1 ))
  done

  return 0
}
