source ${z_main}

z.t.describe "z.hash.to_arr"; {
  z.t.context "name, ageを持つハッシュが渡された場合"; {
    z.t.it "key:value形式で結合された配列が返る"; {
      local -A hash
      hash[name]="John"
      hash[age]="30"

      z.hash.to_arr hash
      local rep=$REPLY

      z.t.expect.include $rep "name:John"
      z.t.expect.include $rep "age:30"
    }
  }

  z.t.context "空のハッシュが渡された場合"; {
    z.t.it "空の配列を返す"; {
      local -A empty_hash

      z.hash.to_arr empty_hash
      z.t.expect.reply.null
    }
  }
}

z.t.describe "z.hash.merge"; {
  z.t.context "2つのハッシュが渡された場合"; {
    z.t.it "両方のキーと値を持つ新しいハッシュが返る"; {
      local -A hash1
      hash1[name]="John"
      local -A hash2
      hash2[age]="30"

      z.hash.merge base=hash1 other=hash2
      local -A merged_hash=($REPLY)

      z.t.expect ${merged_hash[name]} "John"
      z.t.expect ${merged_hash[age]} "30"
    }
  }

  z.t.context "重複するキーを持つ2つのハッシュが渡された場合"; {
    z.t.it "後のハッシュの値で上書きされた新しいハッシュが返る"; {
      local -A hash1
      hash1[name]="John"
      local -A hash2
      hash2[name]="Doe"

      z.hash.merge base=hash1 other=hash2
      local -A merged_hash=($REPLY)

      z.t.expect ${merged_hash[name]} "Doe"
    }
  }
}
