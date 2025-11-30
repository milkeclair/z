source ${z_main}

z.t.describe "z.hash.has_key"; {
  z.t.context "指定したキーが存在する場合"; {
    z.t.it "成功ステータスを返す"; {
      local -A hash
      hash[name]="John"
      hash[age]="30"

      z.hash.has_key hash name
      z.t.expect.status.true

      z.hash.has_key hash age
      z.t.expect.status.true
    }
  }

  z.t.context "指定したキーが存在しない場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A hash
      hash[name]="John"

      z.hash.has_key hash unknown
      z.t.expect.status.false
    }
  }

  z.t.context "空のハッシュの場合"; {
    z.t.it "失敗ステータスを返す"; {
      local -A empty_hash

      z.hash.has_key empty_hash any_key
      z.t.expect.status.false
    }
  }
}
