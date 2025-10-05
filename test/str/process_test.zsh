source ${z_main}

z.t.describe "z.str.indent"; {
  z.t.context "インデントレベルと文字列が渡された場合"; {
    z.t.it "指定されたレベルでインデントされた文字列を返す"; {
      z.str.indent 2 "Hello"
      z.t.expect_reply "    Hello"

      z.str.indent 0 "No Indent"
      z.t.expect_reply "No Indent"

      z.str.indent 3 "Indented"
      z.t.expect_reply "      Indented"
    }
  }

  z.t.context "インデントレベルが渡されなかった場合"; {
    z.t.it "インデントなしの文字列を返す"; {
      z.str.indent "" "No Indent"
      z.t.expect_reply "No Indent"
    }
  }

  z.t.context "インデントレベルが0の場合"; {
    z.t.it "インデントなしの文字列を返す"; {
      z.str.indent 0 "No Indent"
      z.t.expect_reply "No Indent"
    }
  }

  z.t.context "インデントレベルが負の数の場合"; {
    z.t.it "インデントなしの文字列を返す"; {
      z.str.indent -1 "Negative Indent"
      z.t.expect_reply "Negative Indent"
    }
  }

  z.t.context "空文字列が渡された場合"; {
    z.t.it "インデントのみの文字列を返す"; {
      z.str.indent 2 ""
      z.t.expect_reply "    "
    }
  }
}

z.t.describe "z.str.split"; {
  z.t.context "区切り文字で分割された文字列が渡された場合"; {
    z.t.it "分割された文字列の配列を返す"; {
      z.str.split "apple|banana|cherry" "|"
      z.t.expect_reply.arr "apple" "banana" "cherry"

      z.str.split "one,two,three" ","
      z.t.expect_reply.arr "one" "two" "three"

      z.str.split "a b c" " "
      z.t.expect_reply.arr "a" "b" "c"
    }
  }

  z.t.context "区切り文字が指定されなかった場合"; {
    z.t.it "デフォルトの区切り文字'|'で分割された文字列の配列を返す"; {
      z.str.split "apple|banana|cherry"
      z.t.expect_reply.arr "apple" "banana" "cherry"

      z.str.split "one|two|three"
      z.t.expect_reply.arr "one" "two" "three"
    }
  }

  z.t.context "区切り文字が存在しない場合"; {
    z.t.it "元の文字列を要素とする配列を返す"; {
      z.str.split "single" "|"
      z.t.expect_reply.arr "single"

      z.str.split "another" ","
      z.t.expect_reply.arr "another"
    }
  }

  z.t.context "空文字列が渡された場合"; {
    z.t.it "空の配列を返す"; {
      z.str.split ""
      z.t.expect_reply.arr

      z.str.split "" ","
      z.t.expect_reply.arr
    }
  }
}

z.t.describe "z.str.gsub"; {
  z.t.context "置換対象の文字列が存在する場合"; {
    z.t.it "指定された文字列をすべて置換した文字列を返す"; {
      z.str.gsub "Hello World" "World" "Zsh"
      z.t.expect_reply "Hello Zsh"

      z.str.gsub "foo bar foo" "foo" "baz"
      z.t.expect_reply "baz bar baz"

      z.str.gsub "aaaaa" "a" "b"
      z.t.expect_reply "bbbbb"
    }
  }

  z.t.context "置換対象の文字列が存在しない場合"; {
    z.t.it "元の文字列をそのまま返す"; {
      z.str.gsub "Hello World" "Ruby" "Zsh"
      z.t.expect_reply "Hello World"

      z.str.gsub "foo bar foo" "xyz" "baz"
      z.t.expect_reply "foo bar foo"
    }
  }

  z.t.context "空文字列が渡された場合"; {
    z.t.it "空文字列を返す"; {
      z.str.gsub "" "a" "b"
      z.t.expect_reply ""

      z.str.gsub "" "" "b"
      z.t.expect_reply ""
    }
  }
}
