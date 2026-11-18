source ${z_main}

z.t.describe "z.cls.instance._owns"; {
  z.t.context "登録したディスパッチの場合"; {
    z.t.it "所有する"; {
      z.cls.store._ensure
      z.cls.instance.commands._install owned_cls.run

      z.cls.instance._owns owned_cls.run

      z.t.expect.status.is.true

      unfunction owned_cls.run
      unset 'z_cls_wrapper_refs[owned_cls.run]'
    }
  }

  z.t.context "ユーザーが本体を置換した場合"; {
    z.t.it "所有と判断しない"; {
      z.cls.store._ensure
      z.cls.instance.commands._install replaced_cls.run
      replaced_cls.run() {
        REPLY=user
      }

      z.cls.instance._owns replaced_cls.run

      z.t.expect.status.is.false

      unfunction replaced_cls.run
      unset 'z_cls_wrapper_refs[replaced_cls.run]'
    }
  }
}
