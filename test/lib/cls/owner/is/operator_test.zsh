source "$z_main"

z.cls.store._ensure

z.t.describe "z.cls.owner.is._writable"; {
  z.t.context "宣言済みの通常のスカラーの場合"; {
    z.t.it "変数名がreferenceでも書き込みを許可する"; {
      local reference=""

      z.cls.owner.is._writable reference

      z.t.expect.status.is.true
    }
  }

  z.t.context "代入先にインスタンスの参照が入っている場合"; {
    z.t.it "参照の上書きを拒否する"; {
      () {
        z.cls.draw OccupiedTarget
        z.cls.drew

        local owner=""
        z.cls.new OccupiedTarget owner
        local reference=$owner

        z.cls.owner.is._writable reference

        z.t.expect.status.is.false

        z.cls.delete owner
      }
    }
  }

  z.t.context "代入先が宣言されていない場合"; {
    z.t.it "未宣言の変数への書き込みを拒否する"; {
      z.cls.owner.is._writable undeclared_gc_target

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.cls.owner.is._current"; {
  z.t.context "所有権を移した場合"; {
    z.t.it "移動先の変数を現在の所有者と判定する"; {
      () {
        z.cls.draw CurrentOwnerAfterMove
        z.cls.drew

        local source_owner=""
        local declaration=""
        z.cls.new CurrentOwnerAfterMove source_owner
        z.cls.owner.move from=source_owner to=declaration

        z.cls.owner.is._current declaration instance="$source_owner"

        z.t.expect.status.is.true

        z.cls.delete declaration
      }
    }

    z.t.it "移動前の変数を現在の所有者として認めない"; {
      () {
        z.cls.draw FormerOwnerAfterMove
        z.cls.drew

        local former=""
        local current=""
        z.cls.new FormerOwnerAfterMove former
        z.cls.owner.move from=former to=current

        z.cls.owner.is._current former instance="$former"

        z.t.expect.status.is.false

        z.cls.delete current
      }
    }
  }

  z.t.context "所有者のマークが欠けている場合"; {
    z.t.it "マーク名の登録がなければ失敗する"; {
      () {
        local -A z_cls_owner_markers=()
        z.cls.draw OwnerWithoutMarker
        z.cls.drew

        local owner=""
        z.cls.new OwnerWithoutMarker owner
        local mark=$z_cls_owner_markers[$owner]
        unset "z_cls_owner_markers[$owner]"

        z.cls.owner.is._current owner instance="$owner"

        z.t.expect.status.is.false

        z_cls_owner_markers[$owner]=$mark
        z.cls.delete owner
      }
    }

    z.t.it "マーク名が空なら失敗する"; {
      () {
        local -A z_cls_owner_markers=()
        z.cls.draw OwnerWithEmptyMarker
        z.cls.drew

        local owner=""
        z.cls.new OwnerWithEmptyMarker owner
        local mark=$z_cls_owner_markers[$owner]
        z_cls_owner_markers[$owner]=""

        z.cls.owner.is._current owner instance="$owner"

        z.t.expect.status.is.false

        z_cls_owner_markers[$owner]=$mark
        z.cls.delete owner
      }
    }
  }

  z.t.context "別のマークに結び付いた変数がある場合"; {
    z.t.it "同じ参照が入っていても所有者として認めない"; {
      () {
        z.cls.draw OwnerWithDifferentMarker
        z.cls.drew

        local owner=""
        z.cls.new OwnerWithDifferentMarker owner
        local -T copied="$owner" other_mark

        z.cls.owner.is._current copied instance="$copied"

        z.t.expect.status.is.false

        z.cls.delete owner
      }
    }
  }
}
