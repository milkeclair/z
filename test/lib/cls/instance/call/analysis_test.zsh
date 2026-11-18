source ${z_main}

z.t.describe "z.cls.instance.call._get"; {
  z.t.context "スカラーを取得する場合"; {
    z.t.it "シェル構文を含む文字列をそのまま返す"; {
      () {
        z.cls.draw DirectGet
          z.cls.attr label default=old
        z.cls.drew
        local object=""
        z.cls.new DirectGet object

        local literal=$'one \'two\'\n$(print -r -- expanded) "three" *'
        $object.label.set "$literal"
        z.cls.instance.call._get "$object" label

        z.t.expect.reply "$literal"

        z.cls.instance.call._get "$object" label extra

        z.t.expect.status.is.false
        z.cls.delete object
      }
    }
  }
}
