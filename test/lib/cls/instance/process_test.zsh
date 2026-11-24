source ${z_main}

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
