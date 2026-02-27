source ${z_main}

z.t.describe "z.is.truthy"; {
  z.t.context "0を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.truthy 0

      z.t.expect.status.is.true
    }
  }

  z.t.context "trueを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.truthy "true"

      z.t.expect.status.is.true
    }
  }

  z.t.context "存在するディレクトリパスを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.truthy "/tmp"

      z.t.expect.status.is.true
    }
  }

  z.t.context "存在するファイルパスを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.truthy "${z_main}"

      z.t.expect.status.is.true
    }
  }

  z.t.context "空ではない文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.truthy "non-empty"

      z.t.expect.status.is.true
    }
  }

  z.t.context "何も指定しなかった場合"; {
    z.t.it "falseを返す"; {
      z.is.truthy # zls: ignore

      z.t.expect.status.is.false
    }
  }

  z.t.context "1を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.truthy 1

      z.t.expect.status.is.false
    }
  }

  z.t.context "falseを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.truthy "false"

      z.t.expect.status.is.false
    }
  }

  z.t.context "存在しないディレクトリパスを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.truthy "/path/to/non-existing-dir"

      z.t.expect.status.is.false
    }
  }

  z.t.context "存在しないファイルパスを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.truthy "/path/to/non-existing-file"

      z.t.expect.status.is.false
    }
  }

  z.t.context "空文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.truthy ""

      z.t.expect.status.is.false
    }
  }

  z.t.context "複数の引数を指定した場合"; {
    z.t.it "最初の引数がtruthyならtrueを返す"; {
      z.is.truthy 0 "false" ""

      z.t.expect.status.is.true
    }

    z.t.it "最初の引数がfalsyならfalseを返す"; {
      z.is.truthy 1 "true" "non-empty"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.is.falsy"; {
  z.t.context "1を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.falsy 1

      z.t.expect.status.is.true
    }
  }

  z.t.context "falseを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.falsy "false"

      z.t.expect.status.is.true
    }
  }

  z.t.context "存在しないディレクトリパスを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.falsy "/path/to/non-existing-dir"

      z.t.expect.status.is.true
    }
  }

  z.t.context "存在しないファイルパスを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.falsy "/path/to/non-existing-file"

      z.t.expect.status.is.true
    }
  }

  z.t.context "空文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.falsy ""

      z.t.expect.status.is.true
    }
  }

  z.t.context "何も指定しなかった場合"; {
    z.t.it "trueを返す"; {
      z.is.falsy # zls: ignore

      z.t.expect.status.is.true
    }
  }

  z.t.context "0を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.falsy 0

      z.t.expect.status.is.false
    }
  }

  z.t.context "trueを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.falsy "true"

      z.t.expect.status.is.false
    }
  }

  z.t.context "存在するディレクトリパスを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.falsy "/tmp"

      z.t.expect.status.is.false
    }
  }

  z.t.context "存在するファイルパスを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.falsy "${z_main}"

      z.t.expect.status.is.false
    }
  }

  z.t.context "空ではない文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.falsy "non-empty"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.is.true"; {
  z.t.context "0を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.true 0

      z.t.expect.status.is.true
    }
  }

  z.t.context "trueを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.true "true"

      z.t.expect.status.is.true
    }
  }

  z.t.context "1を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.true 1

      z.t.expect.status.is.false
    }
  }

  z.t.context "falseを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.true "false"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.is.false"; {
  z.t.context "1を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.false 1

      z.t.expect.status.is.true
    }
  }

  z.t.context "falseを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.false "false"

      z.t.expect.status.is.true
    }
  }

  z.t.context "0を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.false 0

      z.t.expect.status.is.false
    }
  }

  z.t.context "trueを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.false "true"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.is.eq"; {
  z.t.context "同じ文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.eq "string" "string"

      z.t.expect.status.is.true
    }
  }

  z.t.context "空文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.eq "" ""

      z.t.expect.status.is.true
    }
  }

  z.t.context "異なる文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.eq "string1" "string2"

      z.t.expect.status.is.false
    }
  }

  z.t.context "空文字列と非空文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.eq "" "non-empty"

      z.t.expect.status.is.false
    }
  }

  z.t.context "複数の引数を指定した場合"; {
    z.t.it "最初の2つの引数が等しければtrueを返す"; {
      z.is.eq "string" "string" "another"

      z.t.expect.status.is.true
    }

    z.t.it "最初の2つの引数が異なればfalseを返す"; {
      z.is.eq "string1" "string2" "string1"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.is.null"; {
  z.t.context "空文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.null ""

      z.t.expect.status.is.true
    }
  }

  z.t.context "何も指定しなかった場合"; {
    z.t.it "trueを返す"; {
      z.is.null # zls: ignore

      z.t.expect.status.is.true
    }
  }

  z.t.context "空ではない文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.null "non-empty"

      z.t.expect.status.is.false
    }
  }

  z.t.context "スペースのみの文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.null "   "

      z.t.expect.status.is.false
    }
  }
}
