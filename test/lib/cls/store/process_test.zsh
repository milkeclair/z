source ${z_main}

z.t.describe "z.cls.store.ensure"; {
  z.t.context "初期化済みの場合"; {
    z.t.it "既存のクラスと状態を保持する"; {
      z.cls.store.ensure
      z_cls_classes[StorePreserved]=1

      z.cls.store.ensure

      z.t.expect "$z_cls_classes[StorePreserved]" 1

      unset 'z_cls_classes[StorePreserved]'
    }
  }

  z.t.context "ready flagだけが残る場合"; {
    z.t.it "不足したストアを初期化する"; {
      unset z_cls_dispatch_programs
      z_cls_store_ready=1

      z.cls.store.ensure

      z.var.exists z_cls_dispatch_programs

      z.t.expect.status.is.true
    }
  }
}
