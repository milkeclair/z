source "$z_main"
z.cls.store._ensure

z.t.describe "z.cls.owner._writable"; {
  z.t.context "宣言済みの通常のスカラーの場合"; {
    z.t.it "書き込みを許可する"; {
      local target=""

      z.cls.owner._writable target

      z.t.expect.status.is.true
    }
  }

  z.t.context "代入先に変数が宣言されていない場合"; {
    z.t.it "書き込みを拒否する"; {
      z.cls.owner._writable undeclared_gc_target

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.cls.owner._is_current"; {
  z.t.context "所有権を移した場合"; {
    z.t.it "新しい目印のある変数だけを所有者と判定する"; {
      () {
        z.cls.draw CheckCurrentOwner
        z.cls.drew
        local source_owner="" destination=""
        z.cls.new CheckCurrentOwner source_owner || return 1
        z.cls.owner.move from=source_owner to=destination || return 1

        z.cls.owner._is_current source_owner "$source_owner"
        z.t.expect.status.is.false
        z.cls.owner._is_current destination "$destination"
        z.t.expect.status.is.true

        z.cls.delete "$destination"
      }
    }
  }
}
