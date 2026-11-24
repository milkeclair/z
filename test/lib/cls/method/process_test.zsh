source ${z_main}

z.t.describe "z.cls.method.defined"; {
  z.t.context "捕捉結果がある場合"; {
    z.t.it "終了状態を返して消費する"; {
      z_cls_capture_done_result=7

      z.cls.method.defined

      z.t.expect.status 7

      z.var.exists z_cls_capture_done_result

      z.t.expect.status.is.false
    }
  }

  z.t.context "捕捉結果がない場合"; {
    z.t.it "成功する"; {
      unset z_cls_capture_done_result

      z.cls.method.defined

      z.t.expect.status.is.true
    }
  }
}
