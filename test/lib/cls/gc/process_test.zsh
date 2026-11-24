source "$z_main"

z.t.describe "z.cls.gc._collect"; {
  z.t.context "関数内で短命の実体を繰り返し生成する場合"; {
    z.t.it "実行中に解放し、同名の外側の所有者を保つ"; {
      local -A z_cls_instances=() z_cls_scalars=() z_cls_values=() z_cls_members=()
      local -A z_cls_active=() z_cls_owner_markers=() z_cls_wrapper_refs=()
      local -i z_cls_gc_allocations=0

      z.cls.draw CollectInLoop
        z.cls.attr count default=10
      z.cls.drew

      local counter=""
      z.cls.new CollectInLoop counter || return 1

      repeat 70; do
        () {
          local counter=""
          z.cls.new CollectInLoop counter
        } || return 1
      done

      z.hash.count z_cls_instances
      z.int.is.lt "$REPLY" 70

      z.t.expect.status.is.true

      $counter.count.get

      z.t.expect.reply 10

      z.cls.delete "$counter"
      z_cls_gc_allocations=64
      z.cls.gc._collect
    }
  }

  z.t.context "所有変数が消えた実体が実行中の場合"; {
    z.t.it "実行中は回収を待ち、実行後の次の回収で解放する"; {
      local -A z_cls_instances=() z_cls_scalars=() z_cls_values=() z_cls_members=()
      local -A z_cls_active=() z_cls_owner_markers=() z_cls_wrapper_refs=()
      local -i z_cls_gc_allocations=0

      z.cls.draw CollectAfterReturn
      z.cls.drew

      local active_ref=""
      () {
        local target=""
        z.cls.new CollectAfterReturn target
        active_ref=$target
      }
      z_cls_active[$active_ref]=1

      z_cls_gc_allocations=64
      z.cls.gc._collect

      z.var.exists "z_cls_instances[$active_ref]"

      z.t.expect.status.is.true

      unset "z_cls_active[$active_ref]"
      z_cls_gc_allocations=64
      z.cls.gc._collect

      z.var.exists "z_cls_instances[$active_ref]"

      z.t.expect.status.is.false
    }
  }
}
