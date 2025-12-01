source ${z_main}

z.t.describe "z.arr.is.not.eq"; {
  z.t.context "異なる要素を持つ配列が渡された場合"; {
    z.t.it "trueを返す"; {
      z.arr.is.not.eq "a b c" "a b d"

      z.t.expect.status.is.true
    }
  }

  z.t.context "要素の順序が異なる配列が渡された場合"; {
    z.t.it "trueを返す"; {
      z.arr.is.not.eq "a b c" "c b a"

      z.t.expect.status.is.true
    }
  }

  z.t.context "要素数が異なる配列が渡された場合"; {
    z.t.it "trueを返す"; {
      z.arr.is.not.eq "a b c" "a b"

      z.t.expect.status.is.true
    }
  }

  z.t.context "同じ要素を持つ配列が渡された場合"; {
    z.t.it "falseを返す"; {
      z.arr.is.not.eq "a b c" "a b c"

      z.t.expect.status.is.false
    }
  }
}
