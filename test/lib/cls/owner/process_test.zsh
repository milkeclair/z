source "$z_main"

z.t.describe "z.cls.owner.move"; {
  z.t.context "所有権を呼び出し元の変数へ移した場合"; {
    z.t.it "移動元のスコープが終わっても移動先から同じインスタンスを操作できる"; {
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

  z.t.context "移動前の参照を保持している場合"; {
    z.t.it "移動元の変数は以前の参照を保持し、移動先は別の参照を受け取る"; {
      () {
        z.cls.draw KeepFormerReference
        z.cls.drew

        local counter=""
        local saved=""
        z.cls.new KeepFormerReference counter
        local former_reference=$counter

        z.cls.owner.move from=counter to=saved

        z.t.expect "$counter" "$former_reference"
        z.t.expect.not "$saved" "$former_reference"

        z.cls.delete saved
      }
    }

    z.t.it "移動前の参照から呼ぶコマンドを解除する"; {
      () {
        z.cls.draw ReleaseFormerCommands
          z.cls.attr count default=5
        z.cls.drew

        local counter=""
        local saved=""
        z.cls.new ReleaseFormerCommands counter
        local former_reference=$counter

        z.cls.owner.move from=counter to=saved

        z.var.exists "functions[$former_reference.count.get]"

        z.t.expect.status.is.false

        z.cls.delete saved
      }
    }

    z.t.it "移動前の参照を指定した削除を拒否する"; {
      () {
        z.cls.draw KeepMovedInstance
        z.cls.drew

        local counter=""
        local saved=""
        z.cls.new KeepMovedInstance counter
        local former_reference=$counter

        z.cls.owner.move from=counter to=saved
        z.cls.delete "$former_reference" 2>/dev/null

        z.t.expect.status.is.false

        z.cls.delete saved
      }
    }
  }

  z.t.context "移動先のスコープが終了した場合"; {
    z.t.it "移動先からコピーした参照でもメソッドを呼べない"; {
      () {
        z.cls.draw OwnerLifetime
          z.cls.attr count default=5
          z.cls.method value
            $self.count.get
          z.cls.method.defined
        z.cls.drew

        local counter=""
        local moved_reference=""
        z.cls.new OwnerLifetime counter

        () {
          local saved=""
          z.cls.owner.move from=counter to=saved
          moved_reference=$saved
        }

        $moved_reference.value 2>/dev/null

        z.t.expect.status.is.false
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

        z.cls.owner.is._current holder reference="$holder"

        z.t.expect.status.is.true

        z.cls.delete "$holder"
      }
    }
  }
}

z.t.describe "z.cls.owner._bind"; {
  z.t.context "所有者の変数に参照を代入する場合"; {
    z.t.it "呼出元のREPLYを保持する"; {
      () {
        local -A z_cls_owner_markers=()
        local binding=""
        REPLY=before

        z.cls.owner._bind test_reference to=binding
        local bind_status=$? bind_reply=$REPLY

        z.t.expect "$bind_status" 0
        z.t.expect "$bind_reply" before
      }
    }

    z.t.it "変数名がbindingでも呼出元へ参照を代入する"; {
      () {
        local -A z_cls_owner_markers=()
        local binding=""

        z.cls.owner._bind test_reference to=binding

        z.t.expect "$binding" test_reference
      }
    }
  }

  z.t.context "所有者のスコープが終了した場合"; {
    z.t.it "所有者と結び付けたマークを失う"; {
      () {
        local -A z_cls_owner_markers=()
        () {
          local binding=""
          z.cls.owner._bind test_reference to=binding

          z.var.exists "$z_cls_owner_markers[test_reference]"

          z.t.expect.status.is.true
        }

        z.var.exists "$z_cls_owner_markers[test_reference]"

        z.t.expect.status.is.false
      }
    }
  }

  z.t.context "参照とインスタンスIDが異なる場合"; {
    z.t.it "マークをインスタンスIDで登録する"; {
      () {
        local -A z_cls_owner_markers=()
        local instance=""

        z.cls.owner._bind new_reference to=instance instance=original_instance

        z.var.exists "$z_cls_owner_markers[original_instance]"

        z.t.expect.status.is.true
      }
    }
  }

  z.t.context "代入先が指定されていない場合"; {
    z.t.it "必須のtoがなければ失敗する"; {
      z.cls.owner._bind missing_target # zls: ignore missing-named-argument

      z.t.expect.status.is.false
    }
  }
}
