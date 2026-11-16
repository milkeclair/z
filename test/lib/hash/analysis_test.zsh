source ${z_main}

z.t.describe "z.hash.keys"; {
  z.t.context "name, ageを持つハッシュが渡された場合"; {
    z.t.it "キーだけが返る"; {
      local -A hash
      hash[name]="John"
      hash[age]="30"

      z.hash.keys hash
      local rep=$REPLY

      z.t.expect.includes $rep "name"
      z.t.expect.includes $rep "age"
    }
  }

  z.t.context "空のハッシュが渡された場合"; {
    z.t.it "空の配列を返す"; {
      local -A empty_hash

      z.hash.keys empty_hash
      z.t.expect.reply.is.null
    }
  }

  z.t.context "literalがtrueの場合"; {
    z.t.it "単一の真偽値風キーを変換せず配列で返す"; {
      local -A hash=([true]="value")

      z.hash.keys hash literal=true
      local result=("${REPLY[@]}")

      z.t.expect "${#result[@]}" 1
      z.t.expect "${result[1]}" "true"
    }

    z.t.it "空のハッシュを空配列で返す"; {
      local -A hash=()

      z.hash.keys hash literal=true
      local result=("${REPLY[@]}")

      z.t.expect "${#result[@]}" 0
    }
  }
}

z.t.describe "z.hash.values"; {
  z.t.context "nameにJohn, ageに30を持つハッシュが渡された場合"; {
    z.t.it "値だけが返る"; {
      local -A hash
      hash[name]="John"
      hash[age]="30"

      z.hash.values hash
      local rep=$REPLY

      z.t.expect.includes $rep "John"
      z.t.expect.includes $rep "30"
    }
  }

  z.t.context "空のハッシュが渡された場合"; {
    z.t.it "空の配列を返す"; {
      local -A empty_hash

      z.hash.values empty_hash
      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.hash.entries"; {
  z.t.context "nameにJohn, ageに30を持つハッシュが渡された場合"; {
    z.t.it "keyとvalueのペアが交互に返る"; {
      local -A hash
      hash[name]="John"
      hash[age]="30"

      z.hash.entries hash
      local rep=$REPLY

      z.t.expect.includes $rep "name"
      z.t.expect.includes $rep "John"
      z.t.expect.includes $rep "age"
      z.t.expect.includes $rep "30"
    }
  }

  z.t.context "空のハッシュが渡された場合"; {
    z.t.it "空の配列を返す"; {
      local -A empty_hash

      z.hash.entries empty_hash
      z.t.expect.reply.is.null
    }
  }

  z.t.context "literalがtrueの場合"; {
    z.t.it "空の値と書式風の値を含む組を保持する"; {
      local -A hash=([empty]="" [word]="keep_empty=true" [flag]="false")

      z.hash.entries hash literal=true
      local result=("${REPLY[@]}")
      local -A entries=("${result[@]}")

      z.t.expect "${#result[@]}" 6
      z.hash.has.key entries key=empty
      local result_code=$?
      z.t.expect "$result_code" 0
      z.t.expect "${entries[empty]}" ""
      z.t.expect "${entries[word]}" "keep_empty=true"
      z.t.expect "${entries[flag]}" "false"
    }

    z.t.it "空のハッシュを空配列で返す"; {
      local -A hash=()

      z.hash.entries hash literal=true
      local result=("${REPLY[@]}")

      z.t.expect "${#result[@]}" 0
    }
  }
}

z.t.describe "z.hash.count"; {
  z.t.context "要素があるハッシュが渡された場合"; {
    z.t.it "要素数を返す"; {
      local -A hash
      hash[name]="John"
      hash[age]="30"
      hash[city]="Tokyo"

      z.hash.count hash
      z.t.expect.reply "3"
    }
  }

  z.t.context "空のハッシュが渡された場合"; {
    z.t.it "0を返す"; {
      local -A empty_hash

      z.hash.count empty_hash
      z.t.expect.reply "0"
    }
  }

  z.t.context "1つの要素を持つハッシュが渡された場合"; {
    z.t.it "1を返す"; {
      local -A single_hash
      single_hash[key]="value"

      z.hash.count single_hash
      z.t.expect.reply "1"
    }
  }
}
