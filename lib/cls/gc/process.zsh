# 生成が続いていれば、所有者がスコープを抜けた非実行中の実体を解放する。
#
# REPLY: null
# return: 0
#
# example:
#  # 前提: 前回の回収から64個の実体を生成し、一部は所有者のスコープを抜けている
#  z.cls.gc._collect
#  # return: 0
#  # 変更後: 所有者が消えた非実行中の実体を解放済み
z.cls.gc._collect() {
  z.int.is.lt $z_cls_gc_allocations 64 && return 0
  z_cls_gc_allocations=0

  local REPLY=""
  local z_cls_gc_id

  z.hash.keys z_cls_owner_markers
  for z_cls_gc_id in "${REPLY[@]}"; do
    z.var.exists "$z_cls_owner_markers[$z_cls_gc_id]" && continue
    z.is.not.null "${z_cls_active[$z_cls_gc_id]:-}" && continue

    z.cls.instance._release "$z_cls_gc_id"
  done

  return 0
}
