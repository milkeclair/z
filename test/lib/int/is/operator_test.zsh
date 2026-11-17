source ${z_main}

z.t.describe "z.int.is.match"; {
  z.t.context "整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.match 123

      z.t.expect.status.is.true
    }
  }

  z.t.context "文字列の整数が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.match "123"

      z.t.expect.status.is.true
    }
  }

  z.t.context "正の整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.match 123

      z.t.expect.status.is.true
    }
  }

  z.t.context "文字列の正の整数が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.match "123"

      z.t.expect.status.is.true
    }
  }

  z.t.context "負の整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.match -123

      z.t.expect.status.is.true
    }
  }

  z.t.context "文字列の負の整数が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.match "-123"

      z.t.expect.status.is.true
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.match "abc"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.int.is.eq"; {
  z.t.context "同じ整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.eq 123 123

      z.t.expect.status.is.true
    }
  }

  z.t.context "文字列の同じ整数が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.eq "123" "123"

      z.t.expect.status.is.true
    }
  }

  z.t.context "異なる整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.eq 123 456

      z.t.expect.status.is.false
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.eq 123 "abc"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.int.is.zero"; {
  z.t.context "0が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.zero 0

      z.t.expect.status.is.true
    }
  }

  z.t.context "文字列の0が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.zero "0"

      z.t.expect.status.is.true
    }
  }

  z.t.context "0以外の整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.zero 123

      z.t.expect.status.is.false
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.zero "abc"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.int.is.positive"; {
  z.t.context "正の整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.positive 123

      z.t.expect.status.is.true
    }
  }

  z.t.context "文字列の正の整数が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.positive "123"

      z.t.expect.status.is.true
    }
  }

  z.t.context "0が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.positive 0

      z.t.expect.status.is.false
    }
  }

  z.t.context "負の整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.positive -123

      z.t.expect.status.is.false
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.positive "abc"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.int.is.negative"; {
  z.t.context "負の整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.negative -123

      z.t.expect.status.is.true
    }
  }

  z.t.context "文字列の負の整数が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.negative "-123"

      z.t.expect.status.is.true
    }
  }

  z.t.context "0が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.negative 0

      z.t.expect.status.is.false
    }
  }

  z.t.context "正の整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.negative 123

      z.t.expect.status.is.false
    }
  }

  z.t.context "整数値以外が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.negative "abc"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.int.is.gt"; {
  z.t.context "大きい整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.gt 456 123

      z.t.expect.status.is.true
    }
  }

  z.t.context "同じ整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.gt 123 123

      z.t.expect.status.is.false
    }
  }

  z.t.context "小さい整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.gt 123 456

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.int.is.gteq"; {
  z.t.context "大きい整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.gteq 456 123

      z.t.expect.status.is.true
    }
  }

  z.t.context "同じ整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.gteq 123 123

      z.t.expect.status.is.true
    }
  }

  z.t.context "小さい整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.gteq 123 456

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.int.is.lt"; {
  z.t.context "小さい整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.lt 123 456

      z.t.expect.status.is.true
    }
  }

  z.t.context "同じ整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.lt 123 123

      z.t.expect.status.is.false
    }
  }

  z.t.context "大きい整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.lt 456 123

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.int.is.lteq"; {
  z.t.context "小さい整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.lteq 123 456

      z.t.expect.status.is.true
    }
  }

  z.t.context "同じ整数値が渡された場合"; {
    z.t.it "trueを返す"; {
      z.int.is.lteq 123 123

      z.t.expect.status.is.true
    }
  }

  z.t.context "大きい整数値が渡された場合"; {
    z.t.it "falseを返す"; {
      z.int.is.lteq 456 123

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.int.is.between"; {
  z.t.context "値が上下限を含む範囲内の場合"; {
    z.t.it "成功する"; {
      z.int.is.between -2 min=-2 max=10
      z.t.expect.status.is.true

      z.int.is.between 10 min=-2 max=10
      z.t.expect.status.is.true

      z.int.is.between +0002 min=2 max=002
      z.t.expect.status.is.true
    }
  }

  z.t.context "値が範囲外または上下限が逆の場合"; {
    z.t.it "失敗する"; {
      z.int.is.between 11 min=-2 max=10
      z.t.expect.status.is.false

      z.int.is.between -3 min=-2 max=10
      z.t.expect.status.is.false

      z.int.is.between 3 min=10 max=2
      z.t.expect.status.is.false
    }
  }

  z.t.context "符号なしを指定した場合"; {
    z.t.it "十進数字だけを受け付ける"; {
      z.int.is.between 003000 min=1 max=65535 signed=false
      z.t.expect.status.is.true

      z.int.is.between +3000 min=1 max=65535 signed=false
      z.t.expect.status.is.false

      z.int.is.between -1 min=1 max=65535 signed=false
      z.t.expect.status.is.false
    }
  }

  z.t.context "桁数が機械整数を超える場合"; {
    z.t.it "桁あふれせず境界と比較する"; {
      z.int.is.between 18446744073709551617 min=1 max=65535
      z.t.expect.status.is.false

      z.int.is.between 100000000000000000000000000000 min=99999999999999999999999999999 max=100000000000000000000000000001
      z.t.expect.status.is.true
    }
  }

  z.t.context "必須引数が不足または整数でない場合"; {
    z.t.it "失敗する"; {
      z.int.is.between # zls: ignore
      z.t.expect.status.is.false

      z.int.is.between 1 max=2 # zls: ignore
      z.t.expect.status.is.false

      z.int.is.between 1 min=0 # zls: ignore
      z.t.expect.status.is.false

      z.int.is.between "1+2" min=0 max=10
      z.t.expect.status.is.false

      z.int.is.between 1 min=x max=10
      z.t.expect.status.is.false

      z.int.is.between 1 min=0 max=10 signed=unknown
      z.t.expect.status.is.false
    }
  }
}
