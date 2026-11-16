# 実体の作成前に、引数と呼出元の代入先変数を検証する。
#
# $1: 公開済みのクラス名
# $2: 書込み可能な通常のスカラー変数名
# REPLY: null
# return: 0|1
z.cls.new._validate() {
  if ! z.int.is.eq $# 2 || z.is.null "${z_cls_classes[$1]:-}" || ! z.cls.is._attribute "$2"; then
    z.io.error "Expected an existing class and an ordinary instance variable name."
    return 1
  fi

  local z_cls_binding=$2

  local z_cls_binding_type=${parameters[$z_cls_binding]:-}

  if z.str.includes "$z_cls_binding_type" readonly ||
      z.str.includes "$z_cls_binding_type" array ||
      z.str.includes "$z_cls_binding_type" association ||
      z.str.includes "$z_cls_binding_type" integer ||
      z.str.includes "$z_cls_binding_type" float; then
    z.io.error "Instance variable $z_cls_binding must be a writable scalar."
    return 1
  fi

  if z.is.not.null "${z_cls_instances[${(P)z_cls_binding:-}]:-}"; then
    z.io.error "Instance variable $z_cls_binding already holds a reference."
    return 1
  fi

  return 0
}
