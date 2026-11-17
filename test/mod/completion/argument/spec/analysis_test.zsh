source "$z_main"

z.t.describe "z.completion.argument.spec._index"; {
  z.t.it "名前付き・位置・残りの仕様を索引にする"; {
    z.completion.argument.spec._index $'named code code\npositional 2 plain\nrest @ code'
    local -A actual=("${REPLY[@]}")

    z.t.expect "$actual[named.code]" "named code code"
    z.t.expect "$actual[positional.2]" "positional 2 plain"
    z.t.expect "$actual[rest]" "rest @ code"
    z.t.expect "$actual[last]" 2
  }

  z.t.it "空の仕様では最後の位置を0にする"; {
    z.completion.argument.spec._index ""
    local -A actual=("${REPLY[@]}")

    z.t.expect "$actual[last]" 0
    z.hash.count actual
    z.t.expect.reply 1
  }
}

z.t.describe "z.completion.argument.spec._match"; {
  z.t.it "名前付き引数では位置を進めない"; {
    local -A example_specs=([named.code]="named code code" [last]=1)
    z.completion.argument.spec._match specs=example_specs position=0 value=code=print

    z.t.expect.reply.is.arr "named code code" "code=" 0
  }

  z.t.it "通常の引数は位置指定と残りの仕様へ対応させる"; {
    local -A example_specs=([positional.1]="positional 1 plain" [rest]="rest @ code" [last]=1)
    z.completion.argument.spec._match specs=example_specs position=0 value=first
    z.t.expect.reply.is.arr "positional 1 plain" "" 1

    z.completion.argument.spec._match specs=example_specs position=1 value=print
    z.t.expect.reply.is.arr "rest @ code" "" 2
  }

  z.t.it "未宣言の名前付き風の値も位置引数として数える"; {
    local -A example_specs=([positional.1]="positional 1 code" [last]=1)
    z.completion.argument.spec._match specs=example_specs position=0 value=unknown=print

    z.t.expect.reply.is.arr "positional 1 code" "" 1
  }
  z.t.it "文字列APIの予約引数と同じ名前でも値を失わない"; {
    local -A example_specs=([named.literal]="named literal code" [last]=0)
    z.completion.argument.spec._match specs=example_specs position=0 value=literal=print

    z.t.expect.reply.is.arr "named literal code" "literal=" 0
  }

}
