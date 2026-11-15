source ${z_main}

z.t.describe "z.pj.add._value"; {
  z.t.it "booleanやnull相当の文字列をそのまま返す"; {
    local expected
    for expected in true false null void 0 1; do
      z.pj.add._value name "name=$expected"
      local actual=$REPLY
      z.t.expect "$actual" "$expected"
    done
  }
  z.t.it "空白や等号を含む値を最初の一致から返す"; {
    z.pj.add._value dir 'other=value' 'dir=/tmp/some project=name' dir=second
    z.t.expect.reply '/tmp/some project=name'
  }
  z.t.it "未指定や明示された空文字ならREPLYを空にする"; {
    REPLY=previous
    z.pj.add._value name dir=/tmp
    local missing=$REPLY
    z.pj.add._value name name= name=second
    local empty=$REPLY
    z.t.expect "$missing" ""
    z.t.expect "$empty" ""
  }
}
