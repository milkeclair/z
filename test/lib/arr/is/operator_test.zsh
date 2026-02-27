source ${z_main}

z.t.describe "z.arr.is.eq"; {
  z.t.context "同じ要素を持つ配列が渡された場合"; {
    z.t.it "trueを返す"; {
      z.arr.is.eq "a b c" "a b c"

      z.t.expect.status.is.true
    }
  }

  z.t.context "異なる要素を持つ配列が渡された場合"; {
    z.t.it "falseを返す"; {
      z.arr.is.eq "a b c" "a b d"

      z.t.expect.status.is.false
    }
  }

  z.t.context "要素の順序が異なる配列が渡された場合"; {
    z.t.it "falseを返す"; {
      z.arr.is.eq "a b c" "c b a"

      z.t.expect.status.is.false
    }
  }

  z.t.context "要素数が異なる配列が渡された場合"; {
    z.t.it "falseを返す"; {
      z.arr.is.eq "a b c" "a b"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.arr.is.all_true"; {
  z.t.context "すべて条件に一致する配列要素が渡された場合"; {
    z.t.it "trueを返す"; {
      z.arr.is.all_true "celebrate" "elegant" "level" "lemon" operation="z.str.includes arg le"
      z.t.expect.status.is.true

      z.arr.is.all_true "1" "2" "3" "4" "5" operation="z.int.is.positive arg"
      z.t.expect.status.is.true
    }
  }

  z.t.context "一部条件に一致しない配列要素が渡された場合"; {
    z.t.it "falseを返す"; {
      z.arr.is.all_true "celebrate" "elegant" "world" "lemon" operation="z.str.includes arg le"
      z.t.expect.status.is.false

      z.arr.is.all_true "1" "-2" "3" "4" "5" operation="z.int.is.positive arg"
      z.t.expect.status.is.false
    }
  }

  z.t.context "配列要素が渡されなかった場合"; {
    z.t.it "trueを返す"; {
      z.arr.is.all_true operation="z.str.includes arg le"
      z.t.expect.status.is.true

      z.arr.is.all_true operation="z.int.is.positive arg"
      z.t.expect.status.is.true
    }
  }
}

z.t.describe "z.arr.is.all_false"; {
  z.t.context "すべて条件に一致しない配列要素が渡された場合"; {
    z.t.it "trueを返す"; {
      z.arr.is.all_false "world" "python" "bash" operation="z.str.includes arg le"
      z.t.expect.status.is.true

      z.arr.is.all_false "-1" "-2" "-3" operation="z.int.is.positive arg"
      z.t.expect.status.is.true
    }
  }

  z.t.context "一部条件に一致する配列要素が渡された場合"; {
    z.t.it "falseを返す"; {
      z.arr.is.all_false "celebrate" "world" "python" operation="z.str.includes arg le"
      z.t.expect.status.is.false

      z.arr.is.all_false "-1" "2" "-3" operation="z.int.is.positive arg"
      z.t.expect.status.is.false
    }
  }

  z.t.context "配列要素が渡されなかった場合"; {
    z.t.it "trueを返す"; {
      z.arr.is.all_false operation="z.str.includes arg le"
      z.t.expect.status.is.true

      z.arr.is.all_false operation="z.int.is.positive arg"
      z.t.expect.status.is.true
    }
  }
}
