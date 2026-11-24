source ${z_main}

z.t.describe "z.cls.instance.call._get"; {
  z.t.context "属性をまだ更新していない場合"; {
    z.t.it "クラスで指定した初期値を返す"; {
      () {
        z.cls.draw DefaultValue
          z.cls.attr label default=initial
        z.cls.drew
        local object=""
        z.cls.new DefaultValue object

        $object.label.get

        z.t.expect.reply initial

        z.cls.delete object
      }
    }
  }

  z.t.context "属性を空文字列に更新した場合"; {
    z.t.it "空の保存値を返す"; {
      () {
        z.cls.draw EmptyValue
          z.cls.attr label default=initial
        z.cls.drew
        local object=""
        z.cls.new EmptyValue object
        $object.label.set ""

        $object.label.get

        z.t.expect.reply.is.null

        z.cls.delete object
      }
    }
  }

  z.t.context "余分な引数がある場合"; {
    z.t.it "取得を拒否する"; {
      () {
        z.cls.draw GetWithArgument
          z.cls.attr label default=initial
        z.cls.drew
        local object=""
        z.cls.new GetWithArgument object

        $object.label.get extra

        z.t.expect.status.is.false

        z.cls.delete object
      }
    }
  }
}
