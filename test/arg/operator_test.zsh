source ${z_main}

z.t.describe "z.arg.present"; {
  z.t.context "引数が1つ以上ある場合"; {
    z.t.it "trueを返す"; {
      z.arg.present "a" "b" "c"

      z.t.expect.status.true
    }
  }

  z.t.context "引数がない場合"; {
    z.t.it "falseを返す"; {
      z.arg.present

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.arg.empty"; {
  z.t.context "引数が1つ以上ある場合"; {
    z.t.it "falseを返す"; {
      z.arg.empty "a" "b" "c"

      z.t.expect.status.false
    }
  }

  z.t.context "引数がない場合"; {
    z.t.it "trueを返す"; {
      z.arg.empty

      z.t.expect.status.true
    }
  }
}

z.t.describe "z.arg.is_valid"; {
  z.t.context "引数の数が指定した数以上の場合"; {
    z.t.it "trueを返す"; {
      z.arg.is_valid "a" "b" "c" length=2

      z.t.expect.status.true
    }
  }

  z.t.context "引数の数が指定した数より少ない場合"; {
    z.t.it "falseを返す"; {
      z.arg.is_valid "a" "b" "c" length=4

      z.t.expect.status.false
    }
  }

  z.t.context "引数の数が指定した数と同じ場合"; {
    z.t.it "trueを返す"; {
      z.arg.is_valid "a" "b" "c" length=3

      z.t.expect.status.true
    }
  }

  z.t.context "引数を指定しなかった場合"; {
    z.t.it "falseを返す"; {
      z.arg.is_valid length=1

      z.t.expect.status.false
    }
  }
}
