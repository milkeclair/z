source ${z_main}

z.t.describe "z.cls.instance.commands.is._managed"; {
  z.t.context "登録したディスパッチの場合"; {
    z.t.it "所有する"; {
      z.cls.draw OwnedCommand
        z.cls.method run 'REPLY=original'
      z.cls.drew
      z.cls.instance.commands._install owned_cls class=OwnedCommand

      z.cls.instance.commands.is._managed owned_cls.run suffix=run

      z.t.expect.status.is.true

      unfunction owned_cls.run
    }
  }

  z.t.context "ユーザーが本体を置換した場合"; {
    z.t.it "所有と判断しない"; {
      z.cls.draw ReplacedCommand
        z.cls.method run 'REPLY=original'
      z.cls.drew
      z.cls.instance.commands._install replaced_cls class=ReplacedCommand
      replaced_cls.run() {
        REPLY=user
      }

      z.cls.instance.commands.is._managed replaced_cls.run suffix=run

      z.t.expect.status.is.false

      unfunction replaced_cls.run
    }
  }
}
