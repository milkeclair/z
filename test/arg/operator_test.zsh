source ${z_main}

z.t.describe "z.arg.has_any"; {
  z.t.context "引数が1つ以上ある場合"; {
    z.t.it "trueを返す"; {
      z.arg.has_any "a" "b" "c"

      z.t.expect.status.true
    }
  }

  z.t.context "引数がない場合"; {
    z.t.it "falseを返す"; {
      z.arg.has_any

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.arg.has_not_any"; {
  z.t.context "引数が1つ以上ある場合"; {
    z.t.it "falseを返す"; {
      z.arg.has_not_any "a" "b" "c"

      z.t.expect.status.false
    }
  }

  z.t.context "引数がない場合"; {
    z.t.it "trueを返す"; {
      z.arg.has_not_any

      z.t.expect.status.true
    }
  }
}

z.t.describe "z.arg.validate"; {
  z.t.context "引数の数が指定した数以上の場合"; {
    z.t.it "trueを返す"; {
      z.arg.validate 2 "a" "b" "c"

      z.t.expect.status.true
    }
  }

  z.t.context "引数の数が指定した数より少ない場合"; {
    z.t.it "falseを返す"; {
      z.arg.validate 4 "a" "b" "c"

      z.t.expect.status.false
    }
  }

  z.t.context "引数の数が指定した数と同じ場合"; {
    z.t.it "trueを返す"; {
      z.arg.validate 3 "a" "b" "c"

      z.t.expect.status.true
    }
  }

  z.t.context "引数を指定しなかった場合"; {
    z.t.it "falseを返す"; {
      z.arg.validate 1

      z.t.expect.status.false
    }
  }
}
