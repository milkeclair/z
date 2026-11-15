source ${z_main}

z.t.describe "z.cls.is.name"; {
  z.t.context "通常の識別子の場合"; {
    z.t.it "英字・数字・underscoreを受け入れる"; {
      z.cls.is.name Counter_2

      z.t.expect.status.is.true
    }
  }

  z.t.context "予約prefixまたは不正な文字の場合"; {
    z.t.it "拒否する"; {
      z.cls.is.name z_cls_reserved

      z.t.expect.status.is.false
      z.cls.is.name bad-name
      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.cls.is.attribute"; {
  z.t.context "通常の変数名の場合"; {
    z.t.it "受け入れる"; {
      z.cls.store.ensure

      z.cls.is.attribute count

      z.t.expect.status.is.true
    }
  }

  z.t.context "特殊変数または返却変数の場合"; {
    z.t.it "拒否する"; {
      z.cls.store.ensure

      z.cls.is.attribute REPLY

      z.t.expect.status.is.false
      z.cls.is.attribute status
      z.t.expect.status.is.false
    }
  }
}
