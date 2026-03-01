source ${z_main}

z.t.describe "z.int.is.not.match"; {
  z.t.context "整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.not.match 123

      z.t.expect.status.is.false
    }
  }

  z.t.context "文字列の整数が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.not.match "123"

      z.t.expect.status.is.false
    }
  }

  z.t.context "正の整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.not.match 123

      z.t.expect.status.is.false
    }
  }

  z.t.context "文字列の正の整数が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.not.match "123"

      z.t.expect.status.is.false
    }
  }

  z.t.context "負の整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.not.match -123

      z.t.expect.status.is.false
    }
  }

  z.t.context "文字列の負の整数が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.not.match "-123"

      z.t.expect.status.is.false
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.not.match "abc"

      z.t.expect.status.is.true
    }
  }
}

z.t.describe "z.int.is.not.eq"; {
  z.t.context "異なる整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.not.eq 123 456

      z.t.expect.status.is.true
    }
  }

  z.t.context "同じ整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.not.eq 123 123

      z.t.expect.status.is.false
    }
  }

  z.t.context "文字列の同じ整数が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.not.eq "123" "123"

      z.t.expect.status.is.false
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.not.eq 123 "abc"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.int.is.not.zero"; {
  z.t.context "0が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.not.zero 0

      z.t.expect.status.is.false
    }
  }

  z.t.context "文字列の0が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.not.zero "0"

      z.t.expect.status.is.false
    }
  }

  z.t.context "0以外の整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.not.zero 123

      z.t.expect.status.is.true
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.not.zero "abc"

      z.t.expect.status.is.false
    }
  }
}
