source ${z_main}

z.t.describe "z.cls.instance.commands.validate"; {
  z.t.context "未使用名の場合"; {
    z.t.it "受け入れる"; {
      z.cls.store.ensure

      z.cls.instance.commands.validate unused_cls_command.run

      z.t.expect.status.is.true
    }
  }

  z.t.context "既存の通常関数の場合"; {
    z.t.it "拒否する"; {
      z.cls.store.ensure
      existing_cls_command.run() {
        z.return original
      }
      z.t.mock name=z.io.error

      z.cls.instance.commands.validate existing_cls_command.run

      z.t.expect.status.is.false skip_unmock=true

      z.t.mock.result name=z.io.error

      z.t.expect.reply "Command existing_cls_command.run already exists."

      unfunction existing_cls_command.run
    }
  }
}

z.t.describe "z.cls.instance.commands.install"; {
  z.t.context "検証済みのメソッド名の場合"; {
    z.t.it "呼び出し先と引数を渡す"; {
      z.cls.store.ensure
      z.t.mock name=z.cls.instance.call

      z.cls.instance.commands.install installed_cls.run
      installed_cls.run one two

      z.t.mock.result name=z.cls.instance.call

      z.t.expect.reply.is.arr installed_cls method run one two

      unfunction installed_cls.run
      unset 'z_cls_wrapper_refs[installed_cls.run]'
    }
  }

  z.t.context "同じコマンドを複数実体が使う場合"; {
    z.t.it "参照数を加算する"; {
      z.cls.store.ensure

      z.cls.instance.commands.install shared_cls.count.get
      z.cls.instance.commands.install shared_cls.count.get

      z.t.expect "$z_cls_wrapper_refs[shared_cls.count.get]" 2

      unfunction shared_cls.count.get
      unset 'z_cls_wrapper_refs[shared_cls.count.get]'
    }
  }
}
