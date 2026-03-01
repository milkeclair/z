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
