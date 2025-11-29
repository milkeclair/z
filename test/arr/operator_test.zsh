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

z.t.describe "z.arr.true_all"; {
  z.t.context "すべて条件に一致する配列要素が渡された場合"; {
    z.t.it "trueを返す"; {
      z.arr.true_all "celebrate" "elegant" "level" "lemon" operation="z.str.include arg le"
      z.t.expect.status.true

      z.arr.true_all "1" "2" "3" "4" "5" operation="z.int.is_positive arg"
      z.t.expect.status.true
    }
  }

  z.t.context "一部条件に一致しない配列要素が渡された場合"; {
    z.t.it "falseを返す"; {
      z.arr.true_all "celebrate" "elegant" "world" "lemon" operation="z.str.include arg le"
      z.t.expect.status.false

      z.arr.true_all "1" "-2" "3" "4" "5" operation="z.int.is_positive arg"
      z.t.expect.status.false
    }
  }

  z.t.context "配列要素が渡されなかった場合"; {
    z.t.it "trueを返す"; {
      z.arr.true_all operation="z.str.include arg le"
      z.t.expect.status.true

      z.arr.true_all operation="z.int.is_positive arg"
      z.t.expect.status.true
    }
  }
}

z.t.describe "z.arr.false_all"; {
  z.t.context "すべて条件に一致しない配列要素が渡された場合"; {
    z.t.it "trueを返す"; {
      z.arr.false_all "world" "python" "bash" operation="z.str.include arg le"
      z.t.expect.status.true

      z.arr.false_all "-1" "-2" "-3" operation="z.int.is_positive arg"
      z.t.expect.status.true
    }
  }

  z.t.context "一部条件に一致する配列要素が渡された場合"; {
    z.t.it "falseを返す"; {
      z.arr.false_all "celebrate" "world" "python" operation="z.str.include arg le"
      z.t.expect.status.false

      z.arr.false_all "-1" "2" "-3" operation="z.int.is_positive arg"
      z.t.expect.status.false
    }
  }

  z.t.context "配列要素が渡されなかった場合"; {
    z.t.it "trueを返す"; {
      z.arr.false_all operation="z.str.include arg le"
      z.t.expect.status.true

      z.arr.false_all operation="z.int.is_positive arg"
      z.t.expect.status.true
    }
  }
}
