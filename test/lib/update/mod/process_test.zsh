source "$z_main"

z.t.describe "z.update.mod._copy"; {
  z.t.context "選択modと依存modをコピーする場合"; {
    z.t.it "旧設定を保ち選択modの旧fileを置き換える"; {
      local dir="/tmp/z_t/update_mod_copy/with space"
      z.dir.remove path=/tmp/z_t/update_mod_copy
      z.dir.make path="$dir/current/mod/app"
      z.dir.make path="$dir/source/mod/app"
      z.dir.make path="$dir/source/mod/base"
      z.dir.make path="$dir/source/mod/unselected"
      z.dir.make path="$dir/prepared"
      z.file.write path="$dir/current/mod/app/obsolete" content=old
      z.file.write path="$dir/current/mod/.settings" content=settings
      z.file.write path="$dir/source/mod/app/value" content=new_app
      z.file.write path="$dir/source/mod/base/value" content=new_base

      z.update.mod._copy source="$dir/source" current="$dir/current" dir="$dir/prepared" base app
      local copy_status=$?
      local result=$REPLY

      z.t.expect "$copy_status" 0
      REPLY=$result
      z.t.expect.reply.is.null

      z.file.read path="$dir/prepared/mod/app/value"
      z.t.expect.reply new_app

      z.file.read path="$dir/prepared/mod/base/value"
      z.t.expect.reply new_base

      z.file.read path="$dir/prepared/mod/.settings"
      z.t.expect.reply settings

      z.file.not.exists "$dir/prepared/mod/app/obsolete"
      z.t.expect.status.is.true

      z.dir.not.exists "$dir/prepared/mod/unselected"
      z.t.expect.status.is.true

      z.file.read path="$dir/current/mod/app/obsolete"
      z.t.expect.reply old

      z.dir.remove path=/tmp/z_t/update_mod_copy
    }
  }

  z.t.context "選択modがなく現在のmodもない場合"; {
    z.t.it "mod directoryを作らない"; {
      local dir=/tmp/z_t/update_mod_copy/none
      z.dir.make path="$dir/current"
      z.dir.make path="$dir/source/mod/unselected"
      z.dir.make path="$dir/prepared"

      z.update.mod._copy source="$dir/source" current="$dir/current" dir="$dir/prepared"
      local copy_status=$?

      z.t.expect "$copy_status" 0

      z.dir.not.exists "$dir/prepared/mod"
      z.t.expect.status.is.true

      z.dir.remove path=/tmp/z_t/update_mod_copy
    }
  }

  z.t.context "選択modがなく既存設定だけがある場合"; {
    z.t.it "設定だけを保つ"; {
      local dir=/tmp/z_t/update_mod_copy/settings
      z.dir.make path="$dir/current/mod"
      z.dir.make path="$dir/source/mod/unselected"
      z.dir.make path="$dir/prepared"
      z.file.write path="$dir/current/mod/.settings" content=original

      z.update.mod._copy source="$dir/source" current="$dir/current" dir="$dir/prepared"
      local copy_status=$?

      z.t.expect "$copy_status" 0

      z.file.read path="$dir/prepared/mod/.settings"
      z.t.expect.reply original

      z.dir.not.exists "$dir/prepared/mod/unselected"
      z.t.expect.status.is.true

      z.dir.remove path=/tmp/z_t/update_mod_copy
    }
  }

  z.t.context "source引数がない場合"; {
    z.t.it "失敗する"; {
      z.update.mod._copy current=/tmp/current dir=/tmp/prepared # zls: ignore missing-named-argument

      z.t.expect.status.is.false
    }
  }

  z.t.context "current引数がない場合"; {
    z.t.it "失敗する"; {
      z.update.mod._copy source=/tmp/source dir=/tmp/prepared # zls: ignore missing-named-argument

      z.t.expect.status.is.false
    }
  }

  z.t.context "dir引数がない場合"; {
    z.t.it "失敗する"; {
      z.update.mod._copy source=/tmp/source current=/tmp/current # zls: ignore missing-named-argument

      z.t.expect.status.is.false
    }
  }

  z.t.context "配布元に選択modがない場合"; {
    z.t.it "コピーの失敗を返して現行modを保持する"; {
      local dir=/tmp/z_t/update_mod_copy/missing
      z.dir.make path="$dir/current/mod/app"
      z.dir.make path="$dir/source"
      z.dir.make path="$dir/prepared"
      z.file.write path="$dir/current/mod/app/value" content=original

      z.update.mod._copy source="$dir/source" current="$dir/current" dir="$dir/prepared" missing 2>/dev/null
      local copy_status=$?

      z.t.expect "$copy_status" 1

      z.file.read path="$dir/current/mod/app/value"
      z.t.expect.reply original

      z.dir.remove path=/tmp/z_t/update_mod_copy
    }
  }

  z.t.context "準備先にmodがある場合"; {
    z.t.it "上書きせず失敗する"; {
      local dir=/tmp/z_t/update_mod_copy/existing
      z.dir.make path="$dir/current"
      z.dir.make path="$dir/source/mod/app"
      z.dir.make path="$dir/prepared/mod"
      z.file.write path="$dir/prepared/mod/value" content=original

      z.update.mod._copy source="$dir/source" current="$dir/current" dir="$dir/prepared" app
      local copy_status=$?

      z.t.expect "$copy_status" 1

      z.file.read path="$dir/prepared/mod/value"
      z.t.expect.reply original

      z.dir.remove path=/tmp/z_t/update_mod_copy
    }
  }

  z.t.context "cpが失敗した場合"; {
    z.t.it "現在のインストール先を変更しない"; {
      local dir=/tmp/z_t/update_mod_copy/failure
      z.dir.make path="$dir/current/mod/app"
      z.dir.make path="$dir/source/mod/app"
      z.dir.make path="$dir/prepared"
      z.file.write path="$dir/current/mod/app/value" content=original

      z.t.mock name=cp behavior="return 1"

      z.update.mod._copy source="$dir/source" current="$dir/current" dir="$dir/prepared" app
      local copy_status=$?

      z.t.expect "$copy_status" 1

      z.file.read path="$dir/current/mod/app/value"
      z.t.expect.reply original

      z.dir.remove path=/tmp/z_t/update_mod_copy
    }
  }

  z.t.context "現在のmod directoryがlinkの場合"; {
    z.t.it "外部dataを変更しない"; {
      local dir=/tmp/z_t/update_mod_copy/link
      z.dir.make path="$dir/current"
      z.dir.make path="$dir/external/app"
      z.dir.make path="$dir/source/mod/app"
      z.dir.make path="$dir/prepared"
      z.file.write path="$dir/external/app/value" content=original
      z.file.write path="$dir/source/mod/app/value" content=updated
      ln -s "$dir/external" "$dir/current/mod"

      z.update.mod._copy source="$dir/source" current="$dir/current" dir="$dir/prepared" app
      local copy_status=$?

      z.t.expect "$copy_status" 0

      z.file.read path="$dir/prepared/mod/app/value"
      z.t.expect.reply updated

      z.file.read path="$dir/external/app/value"
      z.t.expect.reply original

      z.dir.remove path=/tmp/z_t/update_mod_copy
    }
  }

}

