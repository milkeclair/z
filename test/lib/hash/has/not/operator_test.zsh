source ${z_main}

z.t.describe "z.hash.has.not.key"; {
  z.t.context "指定したキーが存在しない場合"; {
    z.t.it "成功ステータスを返す"; {
      local -A hash
      hash[name]="John"

      z.hash.has.not.key hash key=age
      z.t.expect.status.is.true
      unset hash
    }
  }

  z.t.context "空のハッシュの場合"; {
    z.t.it "成功ステータスを返す"; {
      local -A empty_hash

      z.hash.has.not.key empty_hash key=any_key
      z.t.expect.status.is.true
      unset empty_hash
    }
  }

  z.t.context "指定したキーが存在する場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A hash
      hash[name]="John"

      z.hash.has.not.key hash key=name
      z.t.expect.status.is.false
      unset hash
    }

    z.t.it "値が空でも失敗ステータスを返す"; {
      local -A hash
      hash[name]=""

      z.hash.has.not.key hash key=name
      z.t.expect.status.is.false
      unset hash
    }
  }
}

z.t.describe "z.hash.has.not.value"; {
  z.t.context "指定したキーの値が空の場合"; {
    z.t.it "成功ステータスを返す"; {
      local -A hash
      hash[name]=""

      z.hash.has.not.value hash key=name
      z.t.expect.status.is.true
      unset hash
    }
  }

  z.t.context "指定したキーが存在しない場合"; {
    z.t.it "成功ステータスを返す"; {
      local -A hash
      hash[name]="John"

      z.hash.has.not.value hash key=unknown
      z.t.expect.status.is.true
      unset hash
    }
  }

  z.t.context "指定したキーに値が存在する場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A hash
      hash[name]="John"

      z.hash.has.not.value hash key=name
      z.t.expect.status.is.false
      unset hash
    }
  }

  z.t.context "空のハッシュの場合"; {
    z.t.it "成功ステータスを返す"; {
      local -A empty_hash

      z.hash.has.not.value empty_hash key=any_key
      z.t.expect.status.is.true
      unset empty_hash
    }
  }
}
