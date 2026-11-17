source "$z_main"

z.t.describe "z.completion.argument.record._encode"; {
  z.t.it "空白・空値・APIの引数名と同じ値を失わず復元する"; {
    z.completion.argument.record._encode named code code "a b" "" "delimiter=,"
    local record=$REPLY
    z.completion.argument.record._decode "$record"

    z.t.expect.reply.is.arr named code code "a b" "" "delimiter=,"
  }

  z.t.it "改行と引用を含む許可値も復元する"; {
    local literal=$'first\nsecond'
    z.completion.argument.record._encode "$literal" "a'b" '$(never_run)'
    local record=$REPLY
    z.str.excludes "$record" $'\n'
    z.t.expect.status.is.true

    z.completion.argument.record._decode "$record"

    z.t.expect.reply.is.arr "$literal" "a'b" '$(never_run)'
  }
}

z.t.describe "z.completion.argument.record._decode"; {
  z.t.it "旧形式の未引用レコードも読み込める"; {
    z.completion.argument.record._decode "named code code noop"

    z.t.expect.reply.is.arr named code code noop
  }

  z.t.it "空のレコードは空配列を返す"; {
    z.completion.argument.record._decode ""

    z.t.expect.reply.is.arr
  }
}
