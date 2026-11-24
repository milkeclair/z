source ${z_main}

z.t.describe "z.cls.instance.commands._validate"; {
  z.t.context "未使用名の場合"; {
    z.t.it "受け入れる"; {
      z.cls.store._ensure

      z.cls.instance.commands._validate unused_cls_command.run

      z.t.expect.status.is.true
    }
  }

  z.t.context "既存の通常関数の場合"; {
    z.t.it "拒否する"; {
      z.cls.store._ensure
      existing_cls_command.run() {
        REPLY=original
      }
      z.t.mock name=z.io.error

      z.cls.instance.commands._validate existing_cls_command.run

      z.t.expect.status.is.false skip_unmock=true

      z.t.mock.result name=z.io.error

      z.t.expect.reply "Command existing_cls_command.run already exists."

      unfunction existing_cls_command.run
    }
  }
}

z.t.describe "z.cls.instance.commands._template"; {
  z.t.context "属性の取得テンプレートを作る場合"; {
    z.t.it "登録された本体を照合用に記録する"; {
      z.cls.store._ensure

      z.cls.instance.commands._template template_probe.get member=template_probe handler=z.cls.instance.call._get

      z.t.expect "$functions[z_cls_dispatch_template_probe.get]" "$z_cls_dispatch_programs[template_probe.get]"
    }
  }
}

z.t.describe "z.cls.instance.commands._prepare"; {
  z.t.context "メソッドと属性がある場合"; {
    z.t.it "公開するコマンドの接尾辞を返す"; {
      z.cls.draw PrepareCommands
        z.cls.attr count default=0
        z.cls.method read 'REPLY=$1'
        z.cls.instance.commands._prepare PrepareCommands

        z.t.expect.reply.is.arr read count.get count.set
      z.cls.drew
    }
  }
}

z.t.describe "z.cls.instance.commands._install"; {
  z.t.context "メソッドを公開した場合"; {
    z.t.it "インスタンス参照と入力を呼び出し先へ渡す"; {
      z.cls.draw InstallCommands
        z.cls.method run 'REPLY=$1'
      z.cls.drew
      z.t.mock name=z.cls.instance.call._run

      z.cls.instance.commands._install installed_cls class=InstallCommands
      installed_cls.run one "two words"
      z.t.mock.result name=z.cls.instance.call._run

      z.t.expect.reply.is.arr installed_cls run one "two words"

      z.cls.instance.commands._uninstall installed_cls class=InstallCommands
    }
  }
}

z.t.describe "z.cls.instance.commands._uninstall"; {
  z.t.context "同じクラスのコマンドが別の参照にある場合"; {
    z.t.it "指定した参照のコマンドを解除する"; {
      z.cls.draw UninstallCommands
        z.cls.method run 'REPLY=$1'
      z.cls.drew
      z.cls.instance.commands._install uninstall_cls class=UninstallCommands
      z.cls.instance.commands._install keep_cls class=UninstallCommands

      z.cls.instance.commands._uninstall uninstall_cls class=UninstallCommands
      z.var.exists 'functions[uninstall_cls.run]'

      z.t.expect.status.is.false

      z.var.exists 'functions[keep_cls.run]'

      z.t.expect.status.is.true

      z.cls.instance.commands._uninstall keep_cls class=UninstallCommands
    }
  }
}
