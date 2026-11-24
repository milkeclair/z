source "$z_main"

z.t.describe "z.cls.owner.move"; {
  z.t.context "所有権を呼び出し元の変数へ移した場合"; {
    z.t.it "移動元のスコープが終わっても移動先から同じ実体を操作できる"; {
      () {
        z.cls.draw TransferOwner
          z.cls.attr count default=5
        z.cls.drew

        local to=""
        () {
          local from=""
          z.cls.new TransferOwner from || return 1

          z.cls.owner.move from=from to=to
        }

        z.t.expect.status.is.true

        $to.count.get

        z.t.expect.reply 5

        z.cls.delete "$to"
      }
    }
  }

  z.t.context "移動元より移動先のスコープが短い場合"; {
    z.t.it "古い参照を即座に失効させ、移動先の終了後も呼び出しを拒否する"; {
      () {
        z.cls.draw OwnerLifetime
          z.cls.attr count default=5
          z.cls.method value '$self.count.get'
        z.cls.drew

        local counter="" escaped=""
        z.cls.new OwnerLifetime counter || return 1
        local original=$counter

        () {
          local saved=""
          z.cls.owner.move from=counter to=saved || return 1
          escaped=$saved

          $saved.count.set 7
          $saved.value

          z.t.expect.reply 7
          z.t.expect "$counter" "$original"
          z.t.expect.not "$saved" "$counter"

          z.var.exists "functions[$counter.value]"

          z.t.expect.status.is.false

          z.cls.delete "$original" 2>/dev/null

          z.t.expect.status.is.false
        }

        $escaped.value 2>/dev/null

        z.t.expect.status.is.false

        z.var.exists "z_cls_instances[$original]"

        z.t.expect.status.is.true
      }
    }
  }

  z.t.context "所有者の参照をコピーした変数を移動元にした場合"; {
    z.t.it "既存の所有者を残して拒否する"; {
      () {
        z.cls.draw CopiedMove
        z.cls.drew

        local owner="" saved=""
        z.cls.new CopiedMove owner || return 1
        local copied=$owner

        z.cls.owner.move from=copied to=saved 2>/dev/null

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
        REPLY=before

        z.cls.owner._bind test_reference to=binding
        local bind_status=$? bind_reply=$REPLY

        z.t.expect "$bind_status" 0
        z.t.expect "$bind_reply" before
        z.t.expect "$binding" test_reference

        z.var.exists "$z_cls_owner_markers[test_reference]"

        z.t.expect.status.is.true
      }

      z.var.exists "$z_cls_owner_markers[test_reference]"

      z.t.expect.status.is.false
    }
  }

  z.t.context "参照と実体IDが異なる場合"; {
    z.t.it "代入先へ参照を渡し、目印を実体IDに登録する"; {
      () {
        local -A z_cls_owner_markers=()
        local instance=""

        z.cls.owner._bind new_reference to=instance instance=original_instance

        z.t.expect.status.is.true
        z.t.expect "$instance" new_reference

        z.var.exists "$z_cls_owner_markers[original_instance]"

        z.t.expect.status.is.true

        z.var.exists 'z_cls_owner_markers[new_reference]'

        z.t.expect.status.is.false
      }
    }
  }

  z.t.context "代入先が指定されていない場合"; {
    z.t.it "目印を登録せずに失敗する"; {
      () {
        local -A z_cls_owner_markers=()

        z.cls.owner._bind missing_target # zls: ignore missing-named-argument

        z.t.expect.status.is.false

        z.hash.count z_cls_owner_markers

        z.t.expect.reply 0
      }
    }
  }
}
