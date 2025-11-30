source ${z_main}

z.t.describe "z.str.match.rest"; {
  z.t.context "文字列がパターンにマッチする場合"; {
    z.t.it "マッチしていない部分を返す"; {
      z.str.match.rest "hello_world" "hello_"
      z.t.expect.reply "world"

      z.str.match.rest "foo-bar-baz" "foo-"
      z.t.expect.reply "bar-baz"
    }
  }

  z.t.context "文字列がパターンにマッチしない場合"; {
    z.t.it "空文字列を返す"; {
      z.str.match.rest "hello_world" "world"
      z.t.expect.reply.null

      z.str.match.rest "foo-bar-baz" "baz"
      z.t.expect.reply.null
    }
  }
}

z.t.describe "z.str.match.nth"; {
  z.t.context "文字列がパターンにマッチする場合"; {
    z.t.it "指定されたインデックスのマッチ部分を返す"; {
      z.str.match.nth "one two three" "o*" index=1
      z.t.expect.reply "one"

      z.str.match.nth "apple apricot cherry" "a*" index=2
      z.t.expect.reply "apricot"
    }
  }

  z.t.context "文字列がパターンにマッチしない場合"; {
    z.t.it "空文字列を返す"; {
      z.str.match.nth "one two three" "four" index=1
      z.t.expect.reply.null

      z.str.match.nth "apple banana cherry" "date" index=2
      z.t.expect.reply.null
    }
  }
}
