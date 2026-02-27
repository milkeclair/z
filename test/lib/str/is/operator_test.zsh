source ${z_main}

z.t.describe "z.str.is.empty"; {
  z.t.context "空文字列が渡された場合"; {
    z.t.it "trueを返す"; {
      z.str.is.empty ""

      z.t.expect.status.is.true
    }
  }

  z.t.context "空でない文字列が渡された場合"; {
    z.t.it "falseを返す"; {
      z.str.is.empty "hello"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.str.is.match"; {
  z.t.context "文字列がパターンにマッチする場合"; {
    z.t.it "trueを返す"; {
      z.str.is.match "hello" "h*o"

      z.t.expect.status.is.true
    }
  }

  z.t.context "文字列がパターンにマッチしない場合"; {
    z.t.it "falseを返す"; {
      z.str.is.match "hello" "H*O"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.str.is.path_like"; {
  z.t.context "パス形式の文字列が渡された場合"; {
    z.t.it "trueを返す"; {
      z.str.is.path_like "/usr/local/bin"
      z.t.expect.status.is.true

      z.str.is.path_like "~/documents"
      z.t.expect.status.is.true

      z.str.is.path_like "./script.sh"
      z.t.expect.status.is.true

      z.str.is.path_like "../config"
      z.t.expect.status.is.true

      z.str.is.path_like "."
      z.t.expect.status.is.true

      z.str.is.path_like ".."
      z.t.expect.status.is.true
    }
  }

  z.t.context "パス形式でない文字列が渡された場合"; {
    z.t.it "falseを返す"; {
      z.str.is.path_like "not/a/path"

      z.t.expect.status.is.false
    }
  }
}
