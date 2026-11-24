source ${z_main}

z.t.describe "z.cls.instance._resolve"; {
  z.t.context "公開済みインスタンスの参照の場合"; {
    z.t.it "インスタンスIDを返す"; {
      () {
        z.cls.draw ResolveInstance
        z.cls.drew
        local counter=""
        z.cls.new ResolveInstance counter

        z.cls.instance._resolve "$counter"

        z.t.expect.reply "$counter"

        z.cls.delete counter
      }
    }
  }

  z.t.context "参照を解決できない場合"; {
    z.t.it "失敗する"; {
      z.cls.store._ensure
      z.t.mock name=z.io.error

      z.cls.instance._resolve unknown_reference

      z.t.expect.status.is.false
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
