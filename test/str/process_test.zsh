source ${z_main}

z.t.describe "z.str.color"; {
  z.t.context "z_color_paletteに定義されている色を指定した場合"; {
    z.t.it "指定した色のANSIエスケープ文字を返す"; {
      z.str.color "red"
      z.t.expect.reply $'\033[31m'

      z.str.color "green"
      z.t.expect.reply $'\033[32m'

      z.str.color "yellow"
      z.t.expect.reply $'\033[33m'

      z.str.color "blue"
      z.t.expect.reply $'\033[34m'

      z.str.color "magenta"
      z.t.expect.reply $'\033[35m'

      z.str.color "cyan"
      z.t.expect.reply $'\033[36m'

      z.str.color "white"
      z.t.expect.reply $'\033[37m'

      z.str.color "reset"
      z.t.expect.reply $'\033[0m'
    }
  }

  z.t.context "z_color_paletteに定義されていない色を指定した場合"; {
    z.t.it "空文字列を返す"; {
      z.str.color "unknown_color"
      z.t.expect.reply.null
    }
  }
}

z.t.describe "z.str.indent"; {
  z.t.context "インデントレベルと文字列が渡された場合"; {
    z.t.it "指定されたレベルでインデントされた文字列を返す"; {
      z.str.indent level=2 message="Hello"
      z.t.expect.reply "    Hello"

      z.str.indent level=0 message="No Indent"
      z.t.expect.reply "No Indent"

      z.str.indent level=3 message="Indented"
      z.t.expect.reply "      Indented"
    }
  }

  z.t.context "インデントレベルが渡されなかった場合"; {
    z.t.it "インデントなしの文字列を返す"; {
      z.str.indent message="No Indent" # zls: ignore
      z.t.expect.reply "No Indent"
    }
  }

  z.t.context "インデントレベルが0の場合"; {
    z.t.it "インデントなしの文字列を返す"; {
      z.str.indent level=0 message="No Indent"
      z.t.expect.reply "No Indent"
    }
  }

  z.t.context "インデントレベルが負の数の場合"; {
    z.t.it "インデントなしの文字列を返す"; {
      z.str.indent level=-1 message="Negative Indent"
      z.t.expect.reply "Negative Indent"
    }
  }

  z.t.context "空文字列が渡された場合"; {
    z.t.it "インデントのみの文字列を返す"; {
      z.str.indent level=2 message=""
      z.t.expect.reply "    "
    }
  }
}

z.t.describe "z.str.split"; {
  z.t.context "区切り文字で分割された文字列が渡された場合"; {
    z.t.it "分割された文字列の配列を返す"; {
      z.str.split "str=apple|banana|cherry" delimiter="|"
      z.t.expect.reply.arr "apple" "banana" "cherry"

      z.str.split "str=one,two,three" delimiter=","
      z.t.expect.reply.arr "one" "two" "three"

      z.str.split "str=a b c" delimiter=" "
      z.t.expect.reply.arr "a" "b" "c"
    }
  }

  z.t.context "区切り文字が指定されなかった場合"; {
    z.t.it "デフォルトの区切り文字'|'で分割された文字列の配列を返す"; {
      z.str.split "str=apple|banana|cherry"
      z.t.expect.reply.arr "apple" "banana" "cherry"

      z.str.split "str=one|two|three"
      z.t.expect.reply.arr "one" "two" "three"
    }
  }

  z.t.context "区切り文字が存在しない場合"; {
    z.t.it "元の文字列を要素とする配列を返す"; {
      z.str.split str="single" delimiter="|"
      z.t.expect.reply.arr "single"

      z.str.split str="another" delimiter=","
      z.t.expect.reply.arr "another"
    }
  }

  z.t.context "空文字列が渡された場合"; {
    z.t.it "空の配列を返す"; {
      z.str.split str=""
      z.t.expect.reply.null

      z.str.split str="" delimiter=","
      z.t.expect.reply.null
    }
  }
}

z.t.describe "z.str.gsub"; {
  z.t.context "置換対象の文字列が存在する場合"; {
    z.t.it "指定された文字列をすべて置換した文字列を返す"; {
      z.str.gsub str="Hello World" search="World" replace="Zsh"
      z.t.expect.reply "Hello Zsh"

      z.str.gsub str="foo bar foo" search="foo" replace="baz"
      z.t.expect.reply "baz bar baz"

      z.str.gsub str="aaaaa" search="a" replace="b"
      z.t.expect.reply "bbbbb"
    }
  }

  z.t.context "置換対象の文字列が存在しない場合"; {
    z.t.it "元の文字列をそのまま返す"; {
      z.str.gsub str="Hello World" search="Ruby" replace="Zsh"
      z.t.expect.reply "Hello World"

      z.str.gsub str="foo bar foo" search="xyz" replace="baz"
      z.t.expect.reply "foo bar foo"
    }
  }

  z.t.context "空文字列が渡された場合"; {
    z.t.it "空文字列を返す"; {
      z.str.gsub str="" search="a" replace="b"
      z.t.expect.reply.null

      z.str.gsub str="" search="" replace="b"
      z.t.expect.reply.null
    }
  }
}
