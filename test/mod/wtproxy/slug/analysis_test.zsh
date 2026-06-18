source ${z_main}

z.t.describe "z.wtproxy._slug"; {
  z.t.context "大文字と記号が含まれる場合"; {
    z.t.it "Docker Compose projectで使えるslugを返す"; {
      z.wtproxy._slug "Feat/Hello Proxy!"

      z.t.expect.reply "feat_hello_proxy"
    }
  }

  z.t.context "先頭と末尾が英数字ではない場合"; {
    z.t.it "先頭の記号と末尾のunderscoreやhyphenを除去する"; {
      z.wtproxy._slug "///Feature---"

      z.t.expect.reply "feature"
    }
  }

  z.t.context "有効な文字がない場合"; {
    z.t.it "default slugを返す"; {
      z.wtproxy._slug "!!!"

      z.t.expect.reply "$z_wtproxy_default_slug"
    }
  }
}
