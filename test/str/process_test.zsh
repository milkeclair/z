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

z.t.describe "z.str.match"; {
  z.t.context "文字列がパターンにマッチする場合"; {
    z.t.it "マッチ部分の文字列を返す"; {
      z.str.match "hello" "h*o"
      z.t.expect.reply "hello"

      z.str.match "zsh_scripting" "ing"
      z.t.expect.reply "ing"

      z.str.match "2024-06-15" "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]"
      z.t.expect.reply "2024-06-15"
    }
  }

  z.t.context "文字列がパターンにマッチしない場合"; {
    z.t.it "空文字列を返す"; {
      z.str.match "hello" "H*O"
      z.t.expect.reply.null

      z.str.match "zsh_scripting" "ZSH"
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

  z.t.context "pattern=trueが指定された場合"; {
    z.t.it "globパターンでマッチした部分を置換した文字列を返す"; {
      z.str.gsub str="Hello123World" search="[0-9]" replace="-" pattern=true
      z.t.expect.reply "Hello---World"

      z.str.gsub str="abcXYZde" search="[A-Z]" replace='_$MATCH' pattern=true
      z.t.expect.reply "abc_X_Y_Zde"
    }
  }
}

z.t.describe "z.str.upcase"; {
  z.t.context "小文字を含む文字列が渡された場合"; {
    z.t.it "すべて大文字に変換した文字列を返す"; {
      z.str.upcase "hello world"
      z.t.expect.reply "HELLO WORLD"

      z.str.upcase "Zsh Scripting"
      z.t.expect.reply "ZSH SCRIPTING"
    }
  }

  z.t.context "すでに大文字の文字列が渡された場合"; {
    z.t.it "元の文字列をそのまま返す"; {
      z.str.upcase "HELLO WORLD"
      z.t.expect.reply "HELLO WORLD"

      z.str.upcase "ZSH SCRIPTING"
      z.t.expect.reply "ZSH SCRIPTING"
    }
  }
}

z.t.describe "z.str.downcase"; {
  z.t.context "大文字を含む文字列が渡された場合"; {
    z.t.it "すべて小文字に変換した文字列を返す"; {
      z.str.downcase "HELLO WORLD"
      z.t.expect.reply "hello world"

      z.str.downcase "ZSH SCRIPTING"
      z.t.expect.reply "zsh scripting"
    }
  }

  z.t.context "すでに小文字の文字列が渡された場合"; {
    z.t.it "元の文字列をそのまま返す"; {
      z.str.downcase "hello world"
      z.t.expect.reply "hello world"

      z.str.downcase "zsh scripting"
      z.t.expect.reply "zsh scripting"
    }
  }
}

z.t.describe "z.str.camelize"; {
  z.t.context "単語がスペース、アンダースコア、またはハイフンで区切られた文字列が渡された場合"; {
    z.t.it "キャメルケースに変換した文字列を返す"; {
      z.str.camelize "hello world"
      z.t.expect.reply "helloWorld"

      z.str.camelize "zsh_scripting"
      z.t.expect.reply "zshScripting"

      z.str.camelize "my-variable-name"
      z.t.expect.reply "myVariableName"

      z.str.camelize "ZSH_SCRIPTING_TEST"
      z.t.expect.reply "zshScriptingTest"
    }
  }

  z.t.context "複数の区切り文字が連続している文字列が渡された場合"; {
    z.t.it "キャメルケースに変換した文字列を返す"; {
      z.str.camelize "hello   world"
      z.t.expect.reply "helloWorld"

      z.str.camelize "zsh__scripting"
      z.t.expect.reply "zshScripting"

      z.str.camelize "my--variable--name"
      z.t.expect.reply "myVariableName"

      z.str.camelize "ZSH___SCRIPTING---TEST"
      z.t.expect.reply "zshScriptingTest"
    }
  }

  z.t.context "単語が1つだけの文字列が渡された場合"; {
    z.t.it "元の文字列をそのまま返す"; {
      z.str.camelize "hello"
      z.t.expect.reply "hello"

      z.str.camelize "zsh"
      z.t.expect.reply "zsh"
    }
  }

  z.t.context "すでにキャメルケースの文字列が渡された場合"; {
    z.t.it "元の文字列をそのまま返す"; {
      z.str.camelize "helloWorld"
      z.t.expect.reply "helloWorld"

      z.str.camelize "zshScripting"
      z.t.expect.reply "zshScripting"
    }
  }
}

z.t.describe "z.str.pascalize"; {
  z.t.context "単語がスペース、アンダースコア、またはハイフンで区切られた文字列が渡された場合"; {
    z.t.it "パスカルケースに変換した文字列を返す"; {
      z.str.pascalize "hello world"
      z.t.expect.reply "HelloWorld"

      z.str.pascalize "zsh_scripting"
      z.t.expect.reply "ZshScripting"

      z.str.pascalize "my-variable-name"
      z.t.expect.reply "MyVariableName"

      z.str.pascalize "ZSH_SCRIPTING_TEST"
      z.t.expect.reply "ZshScriptingTest"
    }
  }

  z.t.context "複数の区切り文字が連続している文字列が渡された場合"; {
    z.t.it "パスカルケースに変換した文字列を返す"; {
      z.str.pascalize "hello   world"
      z.t.expect.reply "HelloWorld"

      z.str.pascalize "zsh__scripting"
      z.t.expect.reply "ZshScripting"

      z.str.pascalize "my--variable--name"
      z.t.expect.reply "MyVariableName"

      z.str.pascalize "ZSH___SCRIPTING---TEST"
      z.t.expect.reply "ZshScriptingTest"
    }
  }

  z.t.context "単語が1つだけの文字列が渡された場合"; {
    z.t.it "最初の文字を大文字に変換した文字列を返す"; {
      z.str.pascalize "hello"
      z.t.expect.reply "Hello"

      z.str.pascalize "zsh"
      z.t.expect.reply "Zsh"
    }
  }

  z.t.context "すでにパスカルケースの文字列が渡された場合"; {
    z.t.it "元の文字列をそのまま返す"; {
      z.str.pascalize "Hello World"
      z.t.expect.reply "HelloWorld"

      z.str.pascalize "Zsh Scripting"
      z.t.expect.reply "ZshScripting"
    }
  }
}

z.t.describe "z.str.constantize"; {
  z.t.context "単語がスペース、アンダースコア、またはハイフンで区切られた文字列が渡された場合"; {
    z.t.it "定数形式に変換した文字列を返す"; {
      z.str.constantize "hello world"
      z.t.expect.reply "HELLO_WORLD"

      z.str.constantize "zsh_scripting"
      z.t.expect.reply "ZSH_SCRIPTING"

      z.str.constantize "my-variable-name"
      z.t.expect.reply "MY_VARIABLE_NAME"

      z.str.constantize "Zsh Scripting Test"
      z.t.expect.reply "ZSH_SCRIPTING_TEST"
    }
  }

  z.t.context "複数の区切り文字が連続している文字列が渡された場合"; {
    z.t.it "定数形式に変換した文字列を返す"; {
      z.str.constantize "hello   world"
      z.t.expect.reply "HELLO_WORLD"

      z.str.constantize "zsh__scripting"
      z.t.expect.reply "ZSH_SCRIPTING"

      z.str.constantize "my--variable--name"
      z.t.expect.reply "MY_VARIABLE_NAME"

      z.str.constantize "Zsh___Scripting---Test"
      z.t.expect.reply "ZSH_SCRIPTING_TEST"
    }
  }

  z.t.context "単語が1つだけの文字列が渡された場合"; {
    z.t.it "すべて大文字に変換した文字列を返す"; {
      z.str.constantize "hello"
      z.t.expect.reply "HELLO"

      z.str.constantize "zsh"
      z.t.expect.reply "ZSH"
    }
  }

  z.t.context "すでに定数形式の文字列が渡された場合"; {
    z.t.it "元の文字列をそのまま返す"; {
      z.str.constantize "HELLO_WORLD"
      z.t.expect.reply "HELLO_WORLD"

      z.str.constantize "ZSH_SCRIPTING"
      z.t.expect.reply "ZSH_SCRIPTING"
    }
  }
}

z.t.describe "z.str.underscore"; {
  z.t.context "単語がスペース、アンダースコア、またはハイフンで区切られた文字列が渡された場合"; {
    z.t.it "アンダースコア形式に変換した文字列を返す"; {
      z.str.underscore "Hello World"
      z.t.expect.reply "hello_world"

      z.str.underscore "Zsh-Scripting"
      z.t.expect.reply "zsh_scripting"

      z.str.underscore "My Variable Name"
      z.t.expect.reply "my_variable_name"

      z.str.underscore "ZSH_SCRIPTING_TEST"
      z.t.expect.reply "zsh_scripting_test"
    }
  }

  z.t.context "複数の区切り文字が連続している文字列が渡された場合"; {
    z.t.it "アンダースコア形式に変換した文字列を返す"; {
      z.str.underscore "Hello   World"
      z.t.expect.reply "hello_world"

      z.str.underscore "Zsh--Scripting"
      z.t.expect.reply "zsh_scripting"

      z.str.underscore "My___Variable---Name"
      z.t.expect.reply "my_variable_name"

      z.str.underscore "ZSH___SCRIPTING---TEST"
      z.t.expect.reply "zsh_scripting_test"
    }
  }

  z.t.context "単語が1つだけの文字列が渡された場合"; {
    z.t.it "すべて小文字に変換した文字列を返す"; {
      z.str.underscore "Hello"
      z.t.expect.reply "hello"

      z.str.underscore "Zsh"
      z.t.expect.reply "zsh"
    }
  }

  z.t.context "すでにアンダースコア形式の文字列が渡された場合"; {
    z.t.it "元の文字列をそのまま返す"; {
      z.str.underscore "hello_world"
      z.t.expect.reply "hello_world"

      z.str.underscore "zsh_scripting"
      z.t.expect.reply "zsh_scripting"
    }
  }
}

z.t.describe "z.str.kebabize"; {
  z.t.context "単語がスペース、アンダースコア、またはハイフンで区切られた文字列が渡された場合"; {
    z.t.it "ケバブケースに変換した文字列を返す"; {
      z.str.kebabize "Hello World"
      z.t.expect.reply "hello-world"

      z.str.kebabize "Zsh_Scripting"
      z.t.expect.reply "zsh-scripting"

      z.str.kebabize "My Variable Name"
      z.t.expect.reply "my-variable-name"

      z.str.kebabize "ZSH_SCRIPTING_TEST"
      z.t.expect.reply "zsh-scripting-test"
    }
  }

  z.t.context "複数の区切り文字が連続している文字列が渡された場合"; {
    z.t.it "ケバブケースに変換した文字列を返す"; {
      z.str.kebabize "Hello   World"
      z.t.expect.reply "hello-world"

      z.str.kebabize "Zsh__Scripting"
      z.t.expect.reply "zsh-scripting"

      z.str.kebabize "My---Variable___Name"
      z.t.expect.reply "my-variable-name"

      z.str.kebabize "ZSH---SCRIPTING___TEST"
      z.t.expect.reply "zsh-scripting-test"
    }
  }

  z.t.context "単語が1つだけの文字列が渡された場合"; {
    z.t.it "すべて小文字に変換した文字列を返す"; {
      z.str.kebabize "Hello"
      z.t.expect.reply "hello"

      z.str.kebabize "Zsh"
      z.t.expect.reply "zsh"
    }
  }

  z.t.context "すでにケバブケースの文字列が渡された場合"; {
    z.t.it "元の文字列をそのまま返す"; {
      z.str.kebabize "hello-world"
      z.t.expect.reply "hello-world"

      z.str.kebabize "zsh-scripting"
      z.t.expect.reply "zsh-scripting"
    }
  }
}

z.t.describe "z.str.delimitize"; {
  z.t.context "単語がスペース、アンダースコア、またはハイフンで区切られた文字列が渡された場合"; {
    z.t.it "指定した形式に変換した文字列を返す"; {
      z.str.delimitize "Hello World" delimiter="_" replace_chars="[ ]"
      z.t.expect.reply "hello_world"

      z.str.delimitize "Zsh-Scripting" delimiter=" " replace_chars="[_]"
      z.t.expect.reply "zsh-scripting"

      z.str.delimitize "My_Variable_Name" delimiter="-" replace_chars="[_]"
      z.t.expect.reply "my-variable-name"

      z.str.delimitize "ZSH-SCRIPTING TEST" delimiter="_" replace_chars="[ -]"
      z.t.expect.reply "zsh_scripting_test"
    }
  }

  z.t.context "複数の区切り文字が連続している文字列が渡された場合"; {
    z.t.it "指定した形式に変換した文字列を返す"; {
      z.str.delimitize "Hello   World" delimiter="-" replace_chars="[ ]"
      z.t.expect.reply "hello-world"

      z.str.delimitize "Zsh__Scripting" delimiter=" " replace_chars="[_]"
      z.t.expect.reply "zsh scripting"

      z.str.delimitize "My---Variable___Name" delimiter="_" replace_chars="[-_]"
      z.t.expect.reply "my_variable_name"

      z.str.delimitize "ZSH---SCRIPTING___TEST" delimiter="-" replace_chars="[_]"
      z.t.expect.reply "zsh-scripting-test"
    }
  }
}

z.t.describe "z.str.visible"; {
  z.t.context "非表示文字を含む文字列が渡された場合"; {
    z.t.it "非表示文字をエスケープした文字列を返す"; {
      z.str.visible $'\nHello\tWorld'
      z.t.expect.reply $'\\nHello\\tWorld'

      z.str.visible $'\rCarriage Return'
      z.t.expect.reply $'^MCarriage Return'

      z.str.visible $'\aAlert!'
      z.t.expect.reply $'^GAlert!'
    }
  }

  z.t.context "非表示文字を含まない文字列が渡された場合"; {
    z.t.it "元の文字列をそのまま返す"; {
      z.str.visible "Hello World"
      z.t.expect.reply "Hello World"

      z.str.visible "Zsh Scripting"
      z.t.expect.reply "Zsh Scripting"
    }
  }
}

z.t.describe "z.str.ljust"; {
  z.t.context "指定された幅より短い文字列が渡された場合"; {
    z.t.it "右側にスペースを追加して指定された幅に揃えた文字列を返す"; {
      z.str.ljust "Hello" width=10
      z.t.expect.reply "Hello     "

      z.str.ljust "Zsh" width=5
      z.t.expect.reply "Zsh  "
    }
  }

  z.t.context "指定された幅と同じ長さの文字列が渡された場合"; {
    z.t.it "元の文字列をそのまま返す"; {
      z.str.ljust "Hello" width=5
      z.t.expect.reply "Hello"

      z.str.ljust "Zsh" width=3
      z.t.expect.reply "Zsh"
    }
  }

  z.t.context "指定された幅より長い文字列が渡された場合"; {
    z.t.it "元の文字列をそのまま返す"; {
      z.str.ljust "Hello World" width=5
      z.t.expect.reply "Hello World"

      z.str.ljust "Zsh Scripting" width=10
      z.t.expect.reply "Zsh Scripting"
    }
  }

  z.t.context "fillが指定された場合"; {
    z.t.it "指定された文字で埋めて指定された幅に揃えた文字列を返す"; {
      z.str.ljust "Hello" width=10 fill="*"
      z.t.expect.reply "Hello*****"

      z.str.ljust "Zsh" width=5 fill="-"
      z.t.expect.reply "Zsh--"
    }
  }
}

z.t.describe "z.str.rjust"; {
  z.t.context "指定された幅より短い文字列が渡された場合"; {
    z.t.it "左側にスペースを追加して指定された幅に揃えた文字列を返す"; {
      z.str.rjust "Hello" width=10
      z.t.expect.reply "     Hello"

      z.str.rjust "Zsh" width=5
      z.t.expect.reply "  Zsh"
    }
  }

  z.t.context "指定された幅と同じ長さの文字列が渡された場合"; {
    z.t.it "元の文字列をそのまま返す"; {
      z.str.rjust "Hello" width=5
      z.t.expect.reply "Hello"

      z.str.rjust "Zsh" width=3
      z.t.expect.reply "Zsh"
    }
  }

  z.t.context "指定された幅より長い文字列が渡された場合"; {
    z.t.it "元の文字列をそのまま返す"; {
      z.str.rjust "Hello World" width=5
      z.t.expect.reply "Hello World"

      z.str.rjust "Zsh Scripting" width=10
      z.t.expect.reply "Zsh Scripting"
    }
  }

  z.t.context "fillが指定された場合"; {
    z.t.it "指定された文字で埋めて指定された幅に揃えた文字列を返す"; {
      z.str.rjust "Hello" width=10 fill="*"
      z.t.expect.reply "*****Hello"

      z.str.ljust "Zsh" width=5 fill="-"
      z.t.expect.reply "Zsh--"
    }
  }
}
