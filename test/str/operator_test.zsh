source ${z_main}

z.t.describe "z.str.includes"; {
  z.t.context "文字列が部分文字列を含む場合"; {
    z.t.it "trueを返す"; {
      z.str.includes "hello" "ll"

      z.t.expect.status.is.true
    }
  }

  z.t.context "文字列が部分文字列を含まない場合"; {
    z.t.it "falseを返す"; {
      z.str.includes "hello" "LL"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.str.excludes"; {
  z.t.context "文字列が部分文字列を含む場合"; {
    z.t.it "falseを返す"; {
      z.str.excludes "hello" "ll"

      z.t.expect.status.is.false
    }
  }

  z.t.context "文字列が部分文字列を含まない場合"; {
    z.t.it "trueを返す"; {
      z.str.excludes "hello" "LL"

      z.t.expect.status.is.true
    }
  }
}

z.t.describe "z.str.start_with"; {
  z.t.context "文字列が指定された接頭辞で始まる場合"; {
    z.t.it "trueを返す"; {
      z.str.start_with "hello" "he"

      z.t.expect.status.is.true
    }
  }

  z.t.context "文字列が指定された接頭辞で始まらない場合"; {
    z.t.it "falseを返す"; {
      z.str.start_with "hello" "He"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.str.end_with"; {
  z.t.context "文字列が指定された接尾辞で終わる場合"; {
    z.t.it "trueを返す"; {
      z.str.end_with "hello" "lo"

      z.t.expect.status.is.true
    }
  }

  z.t.context "文字列が指定された接尾辞で終わらない場合"; {
    z.t.it "falseを返す"; {
      z.str.end_with "hello" "LO"

      z.t.expect.status.is.false
    }
  }
}
