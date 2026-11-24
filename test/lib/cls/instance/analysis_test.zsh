source ${z_main}

z.t.describe "z.cls.instance._commands"; {
  z.t.context "属性とメソッドがある場合"; {
    z.t.it "インスタンス参照だけを接頭辞にする"; {
      z.cls.store._ensure
      z_cls_class_methods[CommandList]='increment '
      z_cls_class_attrs[CommandList]='count '

      z.cls.instance._commands CommandList reference=ref

      z.t.expect.reply.is.arr ref.increment ref.count.get ref.count.set
    }
  }

  z.t.context "空のクラスの場合"; {
    z.t.it "空配列を返す"; {
      z.cls.store._ensure
      z_cls_class_methods[EmptyCommandList]=''
      z_cls_class_attrs[EmptyCommandList]=''

      z.cls.instance._commands EmptyCommandList reference=ref

      local reply_type=${(t)REPLY}
      local reply_count=${#REPLY}

      z.t.expect "$reply_count" 0
      z.t.expect.includes "$reply_type" array
    }
  }
}
