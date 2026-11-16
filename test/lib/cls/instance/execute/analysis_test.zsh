source ${z_main}

z.t.describe "z.cls.instance.execute._get"; {
  z.t.context "動的スコープにあるスカラーの場合"; {
    z.t.it "falseを文字列として返す"; {
      () {
        local literal=false

        z.cls.instance.execute._get literal

        z.t.expect.reply false
      }
    }
  }

  z.t.context "空配列の場合"; {
    z.t.it "空配列の形を保つ"; {
      () {
        local -a items=()

        z.cls.instance.execute._get items

        z.t.expect.includes "${(t)REPLY}" array
        z.t.expect "${#REPLY}" 0
      }
    }
  }

  z.t.context "余分な引数がある場合"; {
    z.t.it "取得を拒否する"; {
      () {
        local literal=value

        z.cls.instance.execute._get literal extra

        z.t.expect.status.is.false
      }
    }
  }
}
