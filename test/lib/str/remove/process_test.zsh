source ${z_main}

z.t.describe "z.str.remove.prefix"; {
  z.t.context "文字列が指定された接頭辞で始まる場合"; {
    z.t.it "接頭辞を削除した文字列を返す"; {
      z.str.remove.prefix "pr/123" "pr/"
      z.t.expect.reply "123"

      z.str.remove.prefix "a*b" "a*"
      z.t.expect.reply "b"
    }
  }

  z.t.context "文字列が指定された接頭辞で始まらない場合"; {
    z.t.it "元の文字列を返す"; {
      z.str.remove.prefix "main" "pr/"
      z.t.expect.reply "main"
    }
  }

  z.t.context "接頭辞が空文字列の場合"; {
    z.t.it "元の文字列を返す"; {
      z.str.remove.prefix "main" ""
      z.t.expect.reply "main"
    }
  }
}

z.t.describe "z.str.remove.suffix"; {
  z.t.context "文字列が指定された接尾辞で終わる場合"; {
    z.t.it "接尾辞を削除した文字列を返す"; {
      z.str.remove.suffix "file.zsh" ".zsh"
      z.t.expect.reply "file"

      z.str.remove.suffix "a*b" "*b"
      z.t.expect.reply "a"
    }
  }

  z.t.context "文字列が指定された接尾辞で終わらない場合"; {
    z.t.it "元の文字列を返す"; {
      z.str.remove.suffix "README" ".md"
      z.t.expect.reply "README"
    }
  }

  z.t.context "接尾辞が空文字列の場合"; {
    z.t.it "元の文字列を返す"; {
      z.str.remove.suffix "README" ""
      z.t.expect.reply "README"
    }
  }
}
