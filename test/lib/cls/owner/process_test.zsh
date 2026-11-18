source "$z_main"

z.t.describe "z.cls.owner.move"; {
  z.t.context "所有権を呼び出し元の変数へ移した場合"; {
    z.t.it "移動元のスコープが終わっても移動先から同じ実体を操作できる"; {
      () {
        z.cls.draw TransferOwner
          z.cls.attr count default=5
        z.cls.drew

        local saved=""
        () {
          local counter=""
          z.cls.new TransferOwner counter || return 1
          z.cls.owner.move from=counter to=saved
        }
        z.t.expect.status.is.true

        $saved.count.get
        z.t.expect.reply 5
        z.cls.delete "$saved"
      }
    }
  }

  z.t.context "借用した変数を移動元にした場合"; {
    z.t.it "既存の所有者を残して拒否する"; {
      () {
        z.cls.draw BorrowedMove
        z.cls.drew

        local owner="" saved=""
        z.cls.new BorrowedMove owner || return 1
        local borrowed=$owner

        z.cls.owner.move from=borrowed to=saved 2>/dev/null

        z.t.expect.status.is.false
        z.t.expect.is.null "$saved"
        z.cls.delete "$owner"
      }
    }
  }

  z.t.context "移動先が宣言されていない場合"; {
    z.t.it "新しい変数を作らず、元の所有者を保持する"; {
      () {
        z.cls.draw UndeclaredMoveTarget
        z.cls.drew

        local holder=""
        z.cls.new UndeclaredMoveTarget holder || return 1
        z.cls.owner.move from=holder to=missing_move_binding 2>/dev/null

        z.t.expect.status.is.false
        z.var.exists missing_move_binding
        z.t.expect.status.is.false
        z.cls.owner._is_current holder "$holder"
        z.t.expect.status.is.true

        z.cls.delete "$holder"
      }
    }
  }
}

z.t.describe "z.cls.owner._bind"; {
  z.t.context "寿命を持つ代入先へ参照を渡す場合"; {
    z.t.it "所有者のスコープが終わると目印も消える"; {
      local -A z_cls_owner_markers=()
      () {
        local binding=""
        z.cls.owner._bind test_reference binding

        z.t.expect.status.is.true
        z.t.expect "$binding" test_reference
        z.var.exists "$z_cls_owner_markers[test_reference]"
        z.t.expect.status.is.true
      }

      z.var.exists "$z_cls_owner_markers[test_reference]"
      z.t.expect.status.is.false
    }
  }
}
