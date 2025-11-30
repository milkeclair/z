source ${z_main}

z.t.describe "z.str.empty"; {
  z.t.context "空文字列が渡された場合"; {
    z.t.it "trueを返す"; {
      z.str.empty ""

      z.t.expect.status.true
    }
  }

  z.t.context "空でない文字列が渡された場合"; {
    z.t.it "falseを返す"; {
      z.str.empty "hello"

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.str.not_empty"; {
  z.t.context "空文字列が渡された場合"; {
    z.t.it "falseを返す"; {
      z.str.not_empty ""

      z.t.expect.status.false
    }
  }

  z.t.context "空でない文字列が渡された場合"; {
    z.t.it "trueを返す"; {
      z.str.not_empty "hello"

      z.t.expect.status.true
    }
  }
}

z.t.describe "z.str.is_match"; {
  z.t.context "文字列がパターンにマッチする場合"; {
    z.t.it "trueを返す"; {
      z.str.is_match "hello" "h*o"

      z.t.expect.status.true
    }
  }

  z.t.context "文字列がパターンにマッチしない場合"; {
    z.t.it "falseを返す"; {
      z.str.is_match "hello" "H*O"

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.str.is_not_match"; {
  z.t.context "文字列がパターンにマッチする場合"; {
    z.t.it "falseを返す"; {
      z.str.is_not_match "hello" "h*o"

      z.t.expect.status.false
    }
  }

  z.t.context "文字列がパターンにマッチしない場合"; {
    z.t.it "trueを返す"; {
      z.str.is_not_match "hello" "H*O"

      z.t.expect.status.true
    }
  }
}

z.t.describe "z.str.include"; {
  z.t.context "文字列が部分文字列を含む場合"; {
    z.t.it "trueを返す"; {
      z.str.include "hello" "ll"

      z.t.expect.status.true
    }
  }

  z.t.context "文字列が部分文字列を含まない場合"; {
    z.t.it "falseを返す"; {
      z.str.include "hello" "LL"

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.str.exclude"; {
  z.t.context "文字列が部分文字列を含む場合"; {
    z.t.it "falseを返す"; {
      z.str.exclude "hello" "ll"

      z.t.expect.status.false
    }
  }

  z.t.context "文字列が部分文字列を含まない場合"; {
    z.t.it "trueを返す"; {
      z.str.exclude "hello" "LL"

      z.t.expect.status.true
    }
  }
}

z.t.describe "z.str.start_with"; {
  z.t.context "文字列が指定された接頭辞で始まる場合"; {
    z.t.it "trueを返す"; {
      z.str.start_with "hello" "he"

      z.t.expect.status.true
    }
  }

  z.t.context "文字列が指定された接頭辞で始まらない場合"; {
    z.t.it "falseを返す"; {
      z.str.start_with "hello" "He"

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.str.end_with"; {
  z.t.context "文字列が指定された接尾辞で終わる場合"; {
    z.t.it "trueを返す"; {
      z.str.end_with "hello" "lo"

      z.t.expect.status.true
    }
  }

  z.t.context "文字列が指定された接尾辞で終わらない場合"; {
    z.t.it "falseを返す"; {
      z.str.end_with "hello" "LO"

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.str.is_path_like"; {
  z.t.context "パス形式の文字列が渡された場合"; {
    z.t.it "trueを返す"; {
      z.str.is_path_like "/usr/local/bin"
      z.t.expect.status.true

      z.str.is_path_like "~/documents"
      z.t.expect.status.true

      z.str.is_path_like "./script.sh"
      z.t.expect.status.true

      z.str.is_path_like "../config"
      z.t.expect.status.true
    }
  }

  z.t.context "パス形式でない文字列が渡された場合"; {
    z.t.it "falseを返す"; {
      z.str.is_path_like "not/a/path"

      z.t.expect.status.false
    }
  }
}
