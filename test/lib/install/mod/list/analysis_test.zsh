source "$z_main"

z.t.describe "z.install.mod.list._status"; {
  z.t.context "未インストールの場合"; {
    z.t.it "not-installedを返す"; {
      local fixture=$(mktemp -d /tmp/z_mod_status.XXXXXX)
      z.dir.make path="$fixture/source"

      z.install.mod.list._status source="$fixture/source" installed="$fixture/installed"

      z.t.expect.reply not-installed

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "配布元と内容が一致する場合"; {
    z.t.it "隠しfileとsubdirectoryも比較してinstalledを返す"; {
      local fixture=$(mktemp -d /tmp/z_mod_status.XXXXXX)
      z.dir.make path="$fixture/source/nested"
      z.file.write path="$fixture/source/nested/value" content=same
      z.file.write path="$fixture/source/.settings" content=same
      cp -R "$fixture/source" "$fixture/installed"

      z.install.mod.list._status source="$fixture/source" installed="$fixture/installed"

      z.t.expect.reply installed

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "配布元とfileの内容が異なる場合"; {
    z.t.it "update-availableを返す"; {
      local fixture=$(mktemp -d /tmp/z_mod_status.XXXXXX)
      z.dir.make path="$fixture/source"
      z.dir.make path="$fixture/installed"
      z.file.write path="$fixture/source/value" content=new
      z.file.write path="$fixture/installed/value" content=old

      z.install.mod.list._status source="$fixture/source" installed="$fixture/installed"

      z.t.expect.reply update-available

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "fileの追加・削除がある場合"; {
    for side in source installed; do
      z.t.it "$side側だけにfileがあるとupdate-availableを返す"; {
        local fixture=$(mktemp -d /tmp/z_mod_status.XXXXXX)
        z.dir.make path="$fixture/source"
        z.dir.make path="$fixture/installed"
        z.file.write path="$fixture/$side/only" content=changed

        z.install.mod.list._status source="$fixture/source" installed="$fixture/installed"

        z.t.expect.reply update-available

        z.dir.remove path="$fixture"
      }
    done
  }

  z.t.context "導入済みのmodが配布元にない場合"; {
    z.t.it "installedを返す"; {
      local fixture=$(mktemp -d /tmp/z_mod_status.XXXXXX)
      z.dir.make path="$fixture/installed"

      z.install.mod.list._status source="$fixture/missing" installed="$fixture/installed"

      z.t.expect.reply installed

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "比較中に読み取りerrorが起きた場合"; {
    z.t.it "更新ありと誤認せず失敗する"; {
      local fixture=$(mktemp -d /tmp/z_mod_status.XXXXXX)
      z.dir.make path="$fixture/source"
      z.dir.make path="$fixture/installed"
      z.t.mock name=diff behavior="return 2"

      z.install.mod.list._status source="$fixture/source" installed="$fixture/installed" 2>/dev/null

      z.t.expect.status.is.false

      z.dir.remove path="$fixture"
    }
  }
}
