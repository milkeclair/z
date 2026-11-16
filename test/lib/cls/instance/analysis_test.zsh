source ${z_main}

z.t.describe "z.cls.instance._commands"; {
  z.t.context "属性とメソッドがある場合"; {
    z.t.it "両prefixのコマンドを列挙する"; {
      z.cls.store._ensure
      z_cls_class_methods[CommandList]='increment '
      z_cls_class_attrs[CommandList]='count '

      z.cls.instance._commands CommandList object ref

      z.t.expect.reply.is.arr object.increment object.count.get object.count.set ref.increment ref.count.get ref.count.set
    }
  }

  z.t.context "空のクラスの場合"; {
    z.t.it "空配列を返す"; {
      z.cls.store._ensure
      z_cls_class_methods[EmptyCommandList]=''
      z_cls_class_attrs[EmptyCommandList]=''

      z.cls.instance._commands EmptyCommandList object ref

      z.t.expect.includes "${(t)REPLY}" array
    }
  }
}
