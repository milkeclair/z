source ${z_main}

z.t.describe "z.int.is"; {
  z.t.context "整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is 123

      z.t.expect.status.true
    }
  }

  z.t.context "文字列の整数が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is "123"

      z.t.expect.status.true
    }
  }

  z.t.context "正の整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is 123

      z.t.expect.status.true
    }
  }

  z.t.context "文字列の正の整数が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is "123"

      z.t.expect.status.true
    }
  }

  z.t.context "負の整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is -123

      z.t.expect.status.true
    }
  }

  z.t.context "文字列の負の整数が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is "-123"

      z.t.expect.status.true
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is "abc"

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.int.is_not"; {
  z.t.context "整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_not 123

      z.t.expect.status.false
    }
  }

  z.t.context "文字列の整数が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_not "123"

      z.t.expect.status.false
    }
  }

  z.t.context "正の整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_not 123

      z.t.expect.status.false
    }
  }

  z.t.context "文字列の正の整数が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_not "123"

      z.t.expect.status.false
    }
  }

  z.t.context "負の整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_not -123

      z.t.expect.status.false
    }
  }

  z.t.context "文字列の負の整数が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_not "-123"

      z.t.expect.status.false
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is_not "abc"

      z.t.expect.status.true
    }
  }
}

z.t.describe "z.int.eq"; {
  z.t.context "同じ整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.eq 123 123

      z.t.expect.status.true
    }
  }

  z.t.context "文字列の同じ整数が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.eq "123" "123"

      z.t.expect.status.true
    }
  }

  z.t.context "異なる整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.eq 123 456

      z.t.expect.status.false
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.eq 123 "abc"

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.int.not_eq"; {
  z.t.context "異なる整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.not_eq 123 456

      z.t.expect.status.true
    }
  }

  z.t.context "同じ整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.not_eq 123 123

      z.t.expect.status.false
    }
  }

  z.t.context "文字列の同じ整数が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.not_eq "123" "123"

      z.t.expect.status.false
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.not_eq 123 "abc"

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.int.is_zero"; {
  z.t.context "0が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is_zero 0

      z.t.expect.status.true
    }
  }

  z.t.context "文字列の0が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is_zero "0"

      z.t.expect.status.true
    }
  }

  z.t.context "0以外の整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_zero 123

      z.t.expect.status.false
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_zero "abc"

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.int.is_not_zero"; {
  z.t.context "0が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_not_zero 0

      z.t.expect.status.false
    }
  }

  z.t.context "文字列の0が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_not_zero "0"

      z.t.expect.status.false
    }
  }

  z.t.context "0以外の整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is_not_zero 123

      z.t.expect.status.true
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_not_zero "abc"

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.int.is_positive"; {
  z.t.context "正の整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is_positive 123

      z.t.expect.status.true
    }
  }

  z.t.context "文字列の正の整数が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is_positive "123"

      z.t.expect.status.true
    }
  }

  z.t.context "0が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_positive 0

      z.t.expect.status.false
    }
  }

  z.t.context "負の整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_positive -123

      z.t.expect.status.false
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_positive "abc"

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.int.is_negative"; {
  z.t.context "負の整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is_negative -123

      z.t.expect.status.true
    }
  }

  z.t.context "文字列の負の整数が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is_negative "-123"

      z.t.expect.status.true
    }
  }

  z.t.context "0が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_negative 0

      z.t.expect.status.false
    }
  }

  z.t.context "正の整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_negative 123

      z.t.expect.status.false
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is_negative "abc"

      z.t.expect.status.false
    }
  }
}
