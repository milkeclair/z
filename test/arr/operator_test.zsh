source ${z_main}

z.t.describe "z.arr.eq"; {
  z.t.context "同じ要素を持つ配列が渡された場合"; {
    z.t.it "trueを返す"; {
      z.arr.eq "a b c" "a b c"

      z.t.expect.status.true
    }
  }

  z.t.context "異なる要素を持つ配列が渡された場合"; {
    z.t.it "falseを返す"; {
      z.arr.eq "a b c" "a b d"

      z.t.expect.status.false
    }
  }

  z.t.context "要素の順序が異なる配列が渡された場合"; {
    z.t.it "falseを返す"; {
      z.arr.eq "a b c" "c b a"

      z.t.expect.status.false
    }
  }

  z.t.context "要素数が異なる配列が渡された場合"; {
    z.t.it "falseを返す"; {
      z.arr.eq "a b c" "a b"

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.arr.not_eq"; {
  z.t.context "同じ要素を持つ配列が渡された場合"; {
    z.t.it "falseを返す"; {
      z.arr.not_eq "a b c" "a b c"

      z.t.expect.status.false
    }
  }

  z.t.context "異なる要素を持つ配列が渡された場合"; {
    z.t.it "trueを返す"; {
      z.arr.not_eq "a b c" "a b d"

      z.t.expect.status.true
    }
  }

  z.t.context "要素の順序が異なる配列が渡された場合"; {
    z.t.it "trueを返す"; {
      z.arr.not_eq "a b c" "c b a"

      z.t.expect.status.true
    }
  }

  z.t.context "要素数が異なる配列が渡された場合"; {
    z.t.it "trueを返す"; {
      z.arr.not_eq "a b c" "a b"

      z.t.expect.status.true
    }
  }
}

z.t.describe "z.arr.include"; {
  z.t.context "要素が配列に含まれる場合"; {
    z.t.it "trueを返す"; {
      z.arr.include target=b "a" "b" "c"

      z.t.expect.status.true
    }
  }

  z.t.context "要素が配列に含まれない場合"; {
    z.t.it "falseを返す"; {
      z.arr.include target=d "a" "b" "c"

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.arr.exclude"; {
  z.t.context "要素が配列に含まれない場合"; {
    z.t.it "trueを返す"; {
      z.arr.exclude target=d "a" "b" "c"

      z.t.expect.status.true
    }
  }

  z.t.context "要素が配列に含まれる場合"; {
    z.t.it "falseを返す"; {
      z.arr.exclude target=b "a" "b" "c"

      z.t.expect.status.false
    }
  }
}
