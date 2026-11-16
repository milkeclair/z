source ${z_main}

z.t.describe "z.cls.instance._call"; {
  z.t.context "既存の実体を参照する場合"; {
    z.t.it "メソッドの更新と結果を保存する"; {
      () {
        z.cls.draw DirectCall
        z.cls.attr count 0
        z.cls.fn add '(( count += $1 )); REPLY=$count'
        z.cls.drew
        local object=""
        z.cls.new DirectCall object

        z.cls.instance._call "$object" method add 4

        z.t.expect.reply 4

        object.count.get

        z.t.expect.reply 4

        z.cls.delete object
      }
    }
  }

  z.t.context "存在しない参照の場合"; {
    z.t.it "失敗する"; {
      z.cls.store._ensure
      z.t.mock name=z.io.error

      z.cls.instance._call missing_cls_reference method run

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.cls.instance._execute"; {
  z.t.context "復元済みのスカラーの場合"; {
    z.t.it "変換せず取得する"; {
      () {
        local literal=false

        z.cls.instance._execute unused get literal

        z.t.expect.reply false
      }
    }
  }

  z.t.context "メソッドが非zeroで戻る場合"; {
    z.t.it "終了状態を保持する"; {
      z.cls.store._ensure
      z_cls_instances[execute_ref]=Execute
      z_cls_bodies[Execute:fail]='return 7'

      z.cls.instance._execute execute_ref method fail

      z.t.expect.status 7

      unset 'z_cls_instances[execute_ref]' 'z_cls_bodies[Execute:fail]'
    }
  }

  z.t.context "復元済みのスカラーを更新する場合"; {
    z.t.it "値を代入する"; {
      () {
        local literal=old

        z.cls.instance._execute unused set literal null

        z.t.expect "$literal" null
      }
    }
  }
}

z.t.describe "z.cls.instance._snapshot"; {
  z.t.context "リテラル文字列の場合"; {
    z.t.it "保存後に同じ値を復元できる"; {
      () {
        z.cls.store._ensure
        local literal=null

        z.cls.instance._snapshot snapshot_ref literal
        literal=changed
        eval "$z_cls_values[snapshot_ref:literal]"

        z.t.expect "$literal" null

        unset 'z_cls_values[snapshot_ref:literal]'
      }
    }
  }

  z.t.context "基数付き整数の場合"; {
    z.t.it "canonical snapshotが必要であると返す"; {
      () {
        z.cls.store._ensure
        local -i 16 number=255

        z.cls.instance._snapshot snapshot_ref number

        z.t.expect.status.is.false
      }
    }
  }
}

z.t.describe "z.cls.instance._release"; {
  z.t.context "他の実体が残る場合"; {
    z.t.it "対象だけを解放して生存中の状態を保つ"; {
      () {
        z.cls.draw DirectRelease
        z.cls.attr count 3
        z.cls.drew
        local first=""
        z.cls.new DirectRelease first
        local second=""
        z.cls.new DirectRelease second

        z.cls.instance._release "$first"

        z.var.exists "z_cls_instances[$first]"

        z.t.expect.status.is.false

        second.count.get

        z.t.expect.reply 3

        z.cls.delete second
      }
    }
  }
}
