source ${z_main}

z.t.describe "z.cls.store._names"; {
  z.t.context "呼出元のIFSが異なる場合"; {
    z.t.it "保存した名前と境界を保つ"; {
      () {
        local IFS=:

        z.cls.store._names "value count.get count.set "

        z.t.expect.reply.is.arr value count.get count.set
      }
    }
  }

  z.t.context "名前がない場合"; {
    z.t.it "空の配列を返す"; {
      REPLY=(previous)

      z.cls.store._names ""

      z.t.expect.reply.is.null
    }
  }
}
