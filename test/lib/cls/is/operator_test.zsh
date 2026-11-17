source ${z_main}

z.t.describe "z.cls.is._name"; {
  z.t.context "通常の識別子の場合"; {
    z.t.it "英字・数字・アンダースコアを受け入れる"; {
      z.cls.is._name Counter_2

      z.t.expect.status.is.true
    }
  }

  z.t.context "内部名として使わない接頭辞の場合"; {
    z.t.it "二重アンダースコアから始まる通常の名前を受け入れる"; {
      z.cls.is._name __z_cls_value

      z.t.expect.status.is.true
    }
  }

  z.t.context "予約接頭辞または不正な文字の場合"; {
    z.t.it "拒否する"; {
      z.cls.is._name z_cls_reserved

      z.t.expect.status.is.false

      z.cls.is._name bad-name

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.cls.is._attribute"; {
  z.t.context "通常の変数名の場合"; {
    z.t.it "受け入れる"; {
      z.cls.store._ensure

      z.cls.is._attribute count

      z.t.expect.status.is.true
    }
  }

  z.t.context "特殊変数または返却変数の場合"; {
    z.t.it "拒否する"; {
      z.cls.store._ensure

      z.cls.is._attribute REPLY

      z.t.expect.status.is.false

      z.cls.is._attribute status

      z.t.expect.status.is.false
    }
  }
}
