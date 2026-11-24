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

  z.t.context "代入先に実体への参照がある場合"; {
    z.t.it "変数の名前にかかわらず書き込みを拒否する"; {
      () {
        z.cls.draw OccupiedTarget
        z.cls.drew
        local owner=""
        z.cls.new OccupiedTarget owner
        local binding_type=$owner

        z.cls.owner._writable binding_type

        z.t.expect.status.is.false
        z.cls.delete owner
      }
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
        local source_owner="" declaration=""
        z.cls.new CheckCurrentOwner source_owner || return 1
        z.cls.owner.move from=source_owner to=declaration || return 1

        z.cls.owner._is_current source_owner "$source_owner"
        z.t.expect.status.is.false
        z.cls.owner._is_current declaration "$declaration"
        z.t.expect.status.is.true

        z.cls.delete "$declaration"
      }
    }
  }
}
