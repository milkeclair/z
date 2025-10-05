source ${z_main}

z.t.describe "z.is_truthy"; {
  z.t.context "0を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_truthy 0

      z.t.expect_status.true
    }
  }

  z.t.context "trueを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_truthy "true"

      z.t.expect_status.true
    }
  }

  z.t.context "存在するディレクトリパスを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_truthy "/tmp"

      z.t.expect_status.true
    }
  }

  z.t.context "存在するファイルパスを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_truthy "${z_main}"

      z.t.expect_status.true
    }
  }

  z.t.context "空ではない文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_truthy "non-empty"

      z.t.expect_status.true
    }
  }

  z.t.context "何も指定しなかった場合"; {
    z.t.it "falseを返す"; {
      z.is_truthy

      z.t.expect_status.false
    }
  }

  z.t.context "1を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_truthy 1

      z.t.expect_status.false
    }
  }

  z.t.context "falseを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_truthy "false"

      z.t.expect_status.false
    }
  }

  z.t.context "存在しないディレクトリパスを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_truthy "/path/to/non-existing-dir"

      z.t.expect_status.false
    }
  }

  z.t.context "存在しないファイルパスを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_truthy "/path/to/non-existing-file"

      z.t.expect_status.false
    }
  }

  z.t.context "空文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_truthy ""

      z.t.expect_status.false
    }
  }

  z.t.context "複数の引数を指定した場合"; {
    z.t.it "最初の引数がtruthyならtrueを返す"; {
      z.is_truthy 0 "false" ""

      z.t.expect_status.true
    }

    z.t.it "最初の引数がfalsyならfalseを返す"; {
      z.is_truthy 1 "true" "non-empty"

      z.t.expect_status.false
    }
  }
}

z.t.describe "z.is_falsy"; {
  z.t.context "1を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_falsy 1

      z.t.expect_status.true
    }
  }

  z.t.context "falseを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_falsy "false"

      z.t.expect_status.true
    }
  }

  z.t.context "存在しないディレクトリパスを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_falsy "/path/to/non-existing-dir"

      z.t.expect_status.true
    }
  }

  z.t.context "存在しないファイルパスを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_falsy "/path/to/non-existing-file"

      z.t.expect_status.true
    }
  }

  z.t.context "空文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_falsy ""

      z.t.expect_status.true
    }
  }

  z.t.context "何も指定しなかった場合"; {
    z.t.it "trueを返す"; {
      z.is_falsy

      z.t.expect_status.true
    }
  }

  z.t.context "0を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_falsy 0

      z.t.expect_status.false
    }
  }

  z.t.context "trueを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_falsy "true"

      z.t.expect_status.false
    }
  }

  z.t.context "存在するディレクトリパスを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_falsy "/tmp"

      z.t.expect_status.false
    }
  }

  z.t.context "存在するファイルパスを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_falsy "${z_main}"

      z.t.expect_status.false
    }
  }

  z.t.context "空ではない文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_falsy "non-empty"

      z.t.expect_status.false
    }
  }
}

z.t.describe "z.is_true"; {
  z.t.context "0を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_true 0

      z.t.expect_status.true
    }
  }

  z.t.context "trueを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_true "true"

      z.t.expect_status.true
    }
  }

  z.t.context "1を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_true 1

      z.t.expect_status.false
    }
  }

  z.t.context "falseを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_true "false"

      z.t.expect_status.false
    }
  }
}

z.t.describe "z.is_false"; {
  z.t.context "1を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_false 1

      z.t.expect_status.true
    }
  }

  z.t.context "falseを指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_false "false"

      z.t.expect_status.true
    }
  }

  z.t.context "0を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_false 0

      z.t.expect_status.false
    }
  }

  z.t.context "trueを指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_false "true"

      z.t.expect_status.false
    }
  }
}

z.t.describe "z.eq"; {
  z.t.context "同じ文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.eq "string" "string"

      z.t.expect_status.true
    }
  }

  z.t.context "空文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.eq "" ""

      z.t.expect_status.true
    }
  }

  z.t.context "異なる文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.eq "string1" "string2"

      z.t.expect_status.false
    }
  }

  z.t.context "空文字列と非空文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.eq "" "non-empty"

      z.t.expect_status.false
    }
  }

  z.t.context "複数の引数を指定した場合"; {
    z.t.it "最初の2つの引数が等しければtrueを返す"; {
      z.eq "string" "string" "another"

      z.t.expect_status.true
    }

    z.t.it "最初の2つの引数が異なればfalseを返す"; {
      z.eq "string1" "string2" "string1"

      z.t.expect_status.false
    }
  }
}

z.t.describe "z.not_eq"; {
  z.t.context "異なる文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.not_eq "string1" "string2"

      z.t.expect_status.true
    }
  }

  z.t.context "空文字列と非空文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.not_eq "" "non-empty"

      z.t.expect_status.true
    }
  }

  z.t.context "同じ文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.not_eq "string" "string"

      z.t.expect_status.false
    }
  }

  z.t.context "空文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.not_eq "" ""

      z.t.expect_status.false
    }
  }

  z.t.context "複数の引数を指定した場合"; {
    z.t.it "最初の2つの引数が異なればtrueを返す"; {
      z.not_eq "string1" "string2" "another"

      z.t.expect_status.true
    }

    z.t.it "最初の2つの引数が等しければfalseを返す"; {
      z.not_eq "string" "string" "another"

      z.t.expect_status.false
    }
  }
}

z.t.describe "z.is_null"; {
  z.t.context "空文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_null ""

      z.t.expect_status.true
    }
  }

  z.t.context "何も指定しなかった場合"; {
    z.t.it "trueを返す"; {
      z.is_null

      z.t.expect_status.true
    }
  }

  z.t.context "空ではない文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_null "non-empty"

      z.t.expect_status.false
    }
  }

  z.t.context "スペースのみの文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_null "   "

      z.t.expect_status.false
    }
  }
}

z.t.describe "z.is_not_null"; {
  z.t.context "空ではない文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_not_null "non-empty"

      z.t.expect_status.true
    }
  }

  z.t.context "スペースのみの文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is_not_null "   "

      z.t.expect_status.true
    }
  }

  z.t.context "空文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is_not_null ""

      z.t.expect_status.false
    }
  }

  z.t.context "何も指定しなかった場合"; {
    z.t.it "falseを返す"; {
      z.is_not_null

      z.t.expect_status.false
    }
  }
}
