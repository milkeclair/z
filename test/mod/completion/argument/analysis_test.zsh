source "$z_main"

z.t.describe "z.completion.argument._parse"; {
  z.t.it "code型と許可値、区切り位置を返す"; {
    z.completion.argument._parse "\$behavior? [code | 'call_original']: commands"
    local parsed=("${REPLY[@]}")

    z.t.expect "$parsed[1]" named
    z.t.expect "$parsed[2]" behavior
    z.t.expect "$parsed[3]" code
    z.t.expect "$parsed[5]" call_original
  }

  z.t.it "位置引数と可変長引数を区別する"; {
    z.completion.argument._parse '$1 [code]: commands'
    z.t.expect.reply.is.arr positional 1 code 10

    z.completion.argument._parse '$@ [code]: commands'
    z.t.expect.reply.is.arr rest @ code 10
  }

  z.t.it "型指定のない引数を通常の引数として返す"; {
    z.completion.argument._parse '$name?: function name'
    z.t.expect.reply.is.arr named name plain 7
  }

  z.t.it "引用内のコロンと空白を値として保持する"; {
    z.completion.argument._parse '$code [code | "a:b c" | ""]: commands'
    local parsed=("${REPLY[@]}")

    z.t.expect "$parsed[5]" "a:b c"
    z.t.expect "${#parsed[@]}" 6
    z.t.expect.is.null "$parsed[6]"
  }

  z.t.it "未知の型と不完全な注釈を拒否する"; {
    z.completion.argument._parse '$code [string]: commands'
    z.t.expect.status.is.false

    z.completion.argument._parse '$code [code | "missing]: commands'
    z.t.expect.status.is.false
  }
}

z.t.describe "z.completion.argument._docs"; {
  z.t.it "code引数がある関数の通常引数もキャッシュ用に保持する"; {
    local docs=$'$name: name\n$behavior? [code | \'call_original\']: commands\nexample:\n  $ghost [code]: not a parameter'
    z.completion.argument._docs "$docs"

    z.t.expect.reply $'named name plain\nnamed behavior code call_original'
  }

  z.t.it "code引数がない場合は余分なメタデータを作らない"; {
    z.completion.argument._docs '$name: name'

    z.t.expect.reply.is.null
  }
}

z.t.describe "z.completion.argument._select"; {
  z.t.it "名前付きコードの接頭辞と許可値を返す"; {
    z.completion.argument._select $'named name plain\nnamed behavior code call_original' 3 run_code name=test behavior=print

    z.t.expect.reply.is.arr behavior= call_original
  }

  z.t.it "名前付き引数を除いて位置引数を数える"; {
    z.completion.argument._select $'named name plain\npositional 1 code' 3 run_code name=test print

    z.t.expect.reply.is.arr ""
  }

  z.t.it "位置指定より後の引数へrest型を適用する"; {
    z.completion.argument._select $'positional 1 plain\nrest @ code' 3 run_code first print

    z.t.expect.reply.is.arr ""
  }

  z.t.it "通常の引数と不足したキャッシュでは失敗する"; {
    z.completion.argument._select $'named name plain\nnamed behavior code' 2 run_code name=test
    z.t.expect.status.is.false

    z.completion.argument._select "" 2 run_code value
    z.t.expect.status.is.false
  }
}

z.t.describe "z.completion.argument._value"; {
  z.t.it "閉じた引用と未完の引用を同じ値へ復号する"; {
    z.completion.argument._value "behavior='print ok; z.arg.g"
    z.t.expect.reply "behavior=print ok; z.arg.g"

    z.completion.argument._value "behavior='print ok; z.arg.g'"
    z.t.expect.reply "behavior=print ok; z.arg.g"
  }

  z.t.it "外側の引用だけを外し、内側の引用を保持する"; {
    z.completion.argument._value "code='print \"hello wo"
    z.t.expect.reply 'code=print "hello wo'

    z.completion.argument._value "code=\"print 'hello wo"
    z.t.expect.reply "code=print 'hello wo"
  }

  z.t.it "ANSI引用と引用のない値も扱う"; {
    z.completion.argument._value "code=\$'print ok\nz.arg.g"
    z.t.expect.reply $'code=print ok\nz.arg.g'

    z.completion.argument._value code=z.arg.g
    z.t.expect.reply code=z.arg.g
  }
}
