# 所有者のスコープを抜け、実行中でもないインスタンスを回収する。
# 前回の回収から64個のインスタンスを生成した後に回収を始める。
#
# REPLY: null
# return: 0
#
# example:
#  z.cls.draw CollectCounter
#  z.cls.drew
#  local reference=""
#  () {
#    local counter=""
#    z.cls.new CollectCounter counter
#    reference=$counter
#  }
#  z_cls_gc_allocations=64
#  z.cls.gc._collect
#  # return: 0
#  z.var.exists "z_cls_instances[$reference]"
#  # return: 1
z.cls.gc._collect() {
  if z.int.is.lt "$z_cls_gc_allocations" 64; then
    return 0
  fi

  z_cls_gc_allocations=0

  local REPLY=""
  local instance_id

  z.hash.keys z_cls_owner_markers
  for instance_id in "${REPLY[@]}"; do
    if z.var.exists "${z_cls_owner_markers[$instance_id]-}"; then
      continue
    fi

    if z.is.not.null "${z_cls_active[$instance_id]-}"; then
      continue
    fi

    z.cls.instance._release "$instance_id"
  done

  return 0
}
