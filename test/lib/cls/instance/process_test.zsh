source ${z_main}

z.t.describe "z.cls.instance._resolve"; {
  z.t.context "公開済みインスタンスの参照の場合"; {
    z.t.it "インスタンスIDを返す"; {
      () {
        z.cls.draw ResolveInstance
        z.cls.drew
        local counter=""
        z.cls.new ResolveInstance counter

        local instance_id=""

        z.cls.instance._resolve "$counter" instance_id

        z.t.expect "$instance_id" "$counter"

        z.cls.delete counter
      }
    }
  }

  z.t.context "参照を解決できない場合"; {
    z.t.it "失敗する"; {
      z.cls.store._ensure
      z.t.mock name=z.io.error

      local instance_id=""

      z.cls.instance._resolve unknown_reference instance_id

      z.t.expect.status.is.false
    }
  }

  z.t.context "参照が空の場合"; {
    z.t.it "利用できない参照として失敗する"; {
      z.cls.store._ensure
      z.t.mock name=z.io.error

      local instance_id=""

      z.cls.instance._resolve "" instance_id

      z.t.expect.status.is.false skip_unmock=true

      z.t.mock.result name=z.io.error

      z.t.expect.reply "Instance reference  is not available in this scope."
    }
  }

  z.t.context "実行中の別インスタンスに戻る場合"; {
    z.t.it "再入を拒否する"; {
      () {
        z.cls.draw RecursiveCall
          z.cls.method identity
            REPLY=$self
          z.cls.method.defined
          z.cls.method relay
            "$1.relay_back" "$self"
          z.cls.method.defined
          z.cls.method relay_back
            "$1.identity"
          z.cls.method.defined
        z.cls.drew
        local first=""
        local second=""
        z.cls.new RecursiveCall first
        z.cls.new RecursiveCall second
        z.t.mock name=z.io.error

        $first.relay "$second"

        z.t.expect.status.is.false

        z.cls.delete first
        z.cls.delete second
      }
    }
  }
}

z.t.describe "z.cls.instance._release"; {
  z.t.context "他のインスタンスが残る場合"; {
    z.t.it "対象だけを解放して生存中の状態を保つ"; {
      () {
        z.cls.draw DirectRelease
          z.cls.attr count default=3
        z.cls.drew

        local first=""
        z.cls.new DirectRelease first
        local second=""
        z.cls.new DirectRelease second

        z.cls.instance._release "$first"

        z.var.exists "z_cls_instances[$first]"

        z.t.expect.status.is.false

        $second.count.get

        z.t.expect.reply 3

        z.cls.delete second
      }
    }
  }
}
