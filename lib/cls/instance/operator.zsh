# 再利用や削除の前に、コマンドの本体が登録済みの内容と一致するか検証する。
# 再読込時には、以前の共有本体のキーや個別に保存した呼出し関数も認識する。
#
# $1: 生成済みのコマンド名
# REPLY: 変更しない
# return: 0|1
z.cls.instance._owns() {
  local z_cls_program=${functions[$1]-}
  local z_cls_suffix=${1#*.}
  local z_cls_expected=${z_cls_dispatch_programs[$z_cls_suffix]-}

  if z.is.null "$z_cls_expected"; then
    local z_cls_old_key="method:$z_cls_suffix"

    if z.str.includes "$z_cls_suffix" .; then
      z_cls_old_key="${z_cls_suffix##*.}:${z_cls_suffix%.*}"
    fi

    z_cls_expected=${z_cls_dispatch_programs[$z_cls_old_key]-}
  fi

  if z.is.not.null "$z_cls_program" && z.is.eq "$z_cls_program" "$z_cls_expected"; then
    return 0
  fi

  z.is.not.null "${z_cls_wrapper_bodies[$1]:-}" &&
    z.is.eq "$z_cls_program" "$z_cls_wrapper_bodies[$1]"
}
