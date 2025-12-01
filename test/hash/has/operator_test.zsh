source ${z_main}

z.t.describe "z.hash.has.key"; {
  z.t.context "指定したキーが存在する場合"; {
    z.t.it "成功ステータスを返す"; {
      local -A hash
      hash[name]="John"
      hash[age]="30"

      z.hash.has.key hash key=name
      z.t.expect.status.is.true

      z.hash.has.key hash key=age
      z.t.expect.status.is.true
      unset hash
    }

    z.t.it "値が空でも成功ステータスを返す"; {
      local -A hash
      hash[name]=""

      z.hash.has.key hash key=name
      z.t.expect.status.is.true
      unset hash
    }
  }

  z.t.context "指定したキーが存在しない場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A hash
      hash[name]="John"

      z.hash.has.key hash key=unknown
      z.t.expect.status.is.false
      unset hash
    }
  }

  z.t.context "空のハッシュの場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A empty_hash

      z.hash.has.key empty_hash key=any_key
      z.t.expect.status.is.false
      unset empty_hash
    }
  }
}

z.t.describe "z.hash.has.value"; {
  z.t.context "指定したキーに値が存在する場合"; {
    z.t.it "成功ステータスを返す"; {
      local -A hash
      hash[name]="John"
      hash[age]="30"

      z.hash.has.value hash key=name
      z.t.expect.status.is.true

      z.hash.has.value hash key=age
      z.t.expect.status.is.true
      unset hash
    }
  }

  z.t.context "指定したキーの値が空の場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A hash
      hash[name]=""

      z.hash.has.value hash key=name
      z.t.expect.status.is.false
      unset hash
    }
  }

  z.t.context "指定したキーが存在しない場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A hash
      hash[name]="John"

      z.hash.has.value hash key=unknown
      z.t.expect.status.is.false
      unset hash
    }
  }

  z.t.context "空のハッシュの場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A empty_hash

      z.hash.has.value empty_hash key=any_key
      z.t.expect.status.is.false
      unset empty_hash
    }
  }
}
