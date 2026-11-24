source ${z_main}

z.t.describe "z.cls.instance._commands"; {
  z.t.context "属性とメソッドがある場合"; {
    z.t.it "実体ID付きのコマンドだけを列挙する"; {
      z.cls.store._ensure
      z_cls_class_methods[CommandList]='increment '
      z_cls_class_attrs[CommandList]='count '

      z.cls.instance._commands CommandList ref

      z.t.expect.reply.is.arr ref.increment ref.count.get ref.count.set
    }
  }

  z.t.context "空のクラスの場合"; {
    z.t.it "空配列を返す"; {
      z.cls.store._ensure
      z_cls_class_methods[EmptyCommandList]=''
      z_cls_class_attrs[EmptyCommandList]=''

      z.cls.instance._commands EmptyCommandList ref

      local reply_type=${(t)REPLY}
      local reply_count=${#REPLY}

      z.t.expect "$reply_count" 0
      z.t.expect.includes "$reply_type" array
    }
  }

  z.t.context "クラスを公開したあと"; {
    z.t.it "公開時の一覧から実体のコマンドを返す"; {
      () {
        z.cls.draw PublishedCommandList
          z.cls.attr count default=0
          z.cls.method value '$self.count.get'
          z.cls.method increment '$self.count.set 1'
        z.cls.drew

        local -A z_cls_class_methods=() z_cls_class_attrs=()

        z.cls.instance._commands PublishedCommandList ref
        z.t.expect.reply.is.arr ref.value ref.increment ref.count.get ref.count.set
      }
    }
  }

}
