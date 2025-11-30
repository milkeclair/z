source ${z_main}

z.t.describe "z.hash.has_key"; {
  z.t.context "指定したキーが存在する場合"; {
    z.t.it "成功ステータスを返す"; {
      local -A hash
      hash[name]="John"
      hash[age]="30"

      z.hash.has_key hash key=name
      z.t.expect.status.true

      z.hash.has_key hash key=age
      z.t.expect.status.true
      unset hash
    }

    z.t.it "値が空でも成功ステータスを返す"; {
      local -A hash
      hash[name]=""

      z.hash.has_key hash key=name
      z.t.expect.status.true
      unset hash
    }
  }

  z.t.context "指定したキーが存在しない場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A hash
      hash[name]="John"

      z.hash.has_key hash key=unknown
      z.t.expect.status.false
      unset hash
    }
  }

  z.t.context "空のハッシュの場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A empty_hash

      z.hash.has_key empty_hash key=any_key
      z.t.expect.status.false
      unset empty_hash
    }
  }
}

z.t.describe "z.hash.has_not_key"; {
  z.t.context "指定したキーが存在しない場合"; {
    z.t.it "成功ステータスを返す"; {
      local -A hash
      hash[name]="John"

      z.hash.has_not_key hash key=age
      z.t.expect.status.true
      unset hash
    }
  }

  z.t.context "空のハッシュの場合"; {
    z.t.it "成功ステータスを返す"; {
      local -A empty_hash

      z.hash.has_not_key empty_hash key=any_key
      z.t.expect.status.true
      unset empty_hash
    }
  }

  z.t.context "指定したキーが存在する場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A hash
      hash[name]="John"

      z.hash.has_not_key hash key=name
      z.t.expect.status.false
      unset hash
    }

    z.t.it "値が空でも失敗ステータスを返す"; {
      local -A hash
      hash[name]=""

      z.hash.has_not_key hash key=name
      z.t.expect.status.false
      unset hash
    }
  }
}

z.t.describe "z.hash.has_value"; {
  z.t.context "指定したキーに値が存在する場合"; {
    z.t.it "成功ステータスを返す"; {
      local -A hash
      hash[name]="John"
      hash[age]="30"

      z.hash.has_value hash key=name
      z.t.expect.status.true

      z.hash.has_value hash key=age
      z.t.expect.status.true
      unset hash
    }
  }

  z.t.context "指定したキーの値が空の場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A hash
      hash[name]=""

      z.hash.has_value hash key=name
      z.t.expect.status.false
      unset hash
    }
  }

  z.t.context "指定したキーが存在しない場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A hash
      hash[name]="John"

      z.hash.has_value hash key=unknown
      z.t.expect.status.false
      unset hash
    }
  }

  z.t.context "空のハッシュの場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A empty_hash

      z.hash.has_value empty_hash key=any_key
      z.t.expect.status.false
      unset empty_hash
    }
  }
}

z.t.describe "z.hash.has_not_value"; {
  z.t.context "指定したキーの値が空の場合"; {
    z.t.it "成功ステータスを返す"; {
      local -A hash
      hash[name]=""

      z.hash.has_not_value hash key=name
      z.t.expect.status.true
      unset hash
    }
  }

  z.t.context "指定したキーが存在しない場合"; {
    z.t.it "成功ステータスを返す"; {
      local -A hash
      hash[name]="John"

      z.hash.has_not_value hash key=unknown
      z.t.expect.status.true
      unset hash
    }
  }

  z.t.context "指定したキーに値が存在する場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A hash
      hash[name]="John"

      z.hash.has_not_value hash key=name
      z.t.expect.status.false
      unset hash
    }
  }

  z.t.context "空のハッシュの場合"; {
    z.t.it "成功ステータスを返す"; {
      local -A empty_hash

      z.hash.has_not_value empty_hash key=any_key
      z.t.expect.status.true
      unset empty_hash
    }
  }
}
