source ${z_main}

z.t.describe "z.cls.instance.owns"; {
  z.t.context "登録したディスパッチの場合"; {
    z.t.it "所有する"; {
      z.cls.store.ensure
      z.cls.instance.commands.install owned_cls.run

      z.cls.instance.owns owned_cls.run

      z.t.expect.status.is.true

      unfunction owned_cls.run
      unset 'z_cls_wrapper_refs[owned_cls.run]'
    }
  }

  z.t.context "ユーザーが本体を置換した場合"; {
    z.t.it "所有と判断しない"; {
      z.cls.store.ensure
      z.cls.instance.commands.install replaced_cls.run
      replaced_cls.run() {
        z.return user
      }

      z.cls.instance.owns replaced_cls.run

      z.t.expect.status.is.false

      unfunction replaced_cls.run
      unset 'z_cls_wrapper_refs[replaced_cls.run]'
    }
  }
}
