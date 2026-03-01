source ${z_main}

z.t.describe "z.is.not.eq"; {
  z.t.context "異なる文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.not.eq "string1" "string2"

      z.t.expect.status.is.true
    }
  }

  z.t.context "空文字列と非空文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.not.eq "" "non-empty"

      z.t.expect.status.is.true
    }
  }

  z.t.context "同じ文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.not.eq "string" "string"

      z.t.expect.status.is.false
    }
  }

  z.t.context "空文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.not.eq "" ""

      z.t.expect.status.is.false
    }
  }

  z.t.context "複数の引数を指定した場合"; {
    z.t.it "最初の2つの引数が異なればtrueを返す"; {
      z.is.not.eq "string1" "string2" "another"

      z.t.expect.status.is.true
    }

    z.t.it "最初の2つの引数が等しければfalseを返す"; {
      z.is.not.eq "string" "string" "another"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.is.not.null"; {
  z.t.context "空ではない文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.not.null "non-empty"

      z.t.expect.status.is.true
    }
  }

  z.t.context "スペースのみの文字列を指定した場合"; {
    z.t.it "trueを返す"; {
      z.is.not.null "   "

      z.t.expect.status.is.true
    }
  }

  z.t.context "空文字列を指定した場合"; {
    z.t.it "falseを返す"; {
      z.is.not.null ""

      z.t.expect.status.is.false
    }
  }

  z.t.context "何も指定しなかった場合"; {
    z.t.it "falseを返す"; {
      z.is.not.null # zls: ignore

      z.t.expect.status.is.false
    }
  }
}
