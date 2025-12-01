source ${z_main}

z.t.describe "z.str.is.not.empty"; {
  z.t.context "空文字列が渡された場合"; {
    z.t.it "falseを返す"; {
      z.str.is.not.empty ""

      z.t.expect.status.is.false
    }
  }

  z.t.context "空でない文字列が渡された場合"; {
    z.t.it "trueを返す"; {
      z.str.is.not.empty "hello"

      z.t.expect.status.is.true
    }
  }
}

z.t.describe "z.str.is.not.match"; {
  z.t.context "文字列がパターンにマッチする場合"; {
    z.t.it "falseを返す"; {
      z.str.is.not.match "hello" "h*o"

      z.t.expect.status.is.false
    }
  }

  z.t.context "文字列がパターンにマッチしない場合"; {
    z.t.it "trueを返す"; {
      z.str.is.not.match "hello" "H*O"

      z.t.expect.status.is.true
    }
  }
}

z.t.describe "z.str.is.not.path_like"; {
  z.t.context "パス形式の文字列が渡された場合"; {
    z.t.it "falseを返す"; {
      z.str.is.not.path_like "/usr/local/bin"
      z.t.expect.status.is.false

      z.str.is.not.path_like "~/documents"
      z.t.expect.status.is.false

      z.str.is.not.path_like "./script.sh"
      z.t.expect.status.is.false

      z.str.is.not.path_like "../config"
      z.t.expect.status.is.false

      z.str.is.not.path_like "."
      z.t.expect.status.is.false

      z.str.is.not.path_like ".."
      z.t.expect.status.is.false
    }
  }

  z.t.context "パス形式でない文字列が渡された場合"; {
    z.t.it "trueを返す"; {
      z.str.is.not.path_like "not/a/path"

      z.t.expect.status.is.true
    }
  }
}
