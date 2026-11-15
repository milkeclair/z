source "$z_main"

z.t.describe "z.update.core._copy"; {
  z.t.context "配布元の本体が揃っている場合"; {
    z.t.it "本体だけを新規directoryへコピーする"; {
      local dir="/tmp/z_t/update_core/with space"
      z.dir.remove path=/tmp/z_t/update_core
      z.dir.make path="$dir/source/lib"
      z.dir.make path="$dir/source/test"
      z.dir.make path="$dir/source/mod/unselected"
      z.file.write path="$dir/source/lib/value" content=core

      for file in main.zsh install.zsh uninstall.zsh version.zsh help.zsh README.md; do
        z.file.write path="$dir/source/$file" content="$file"
      done

      z.update.core._copy source="$dir/source" dir="$dir/prepared"
      local copy_status=$?
      local result=$REPLY

      z.t.expect "$copy_status" 0
      REPLY=$result
      z.t.expect.reply.is.null

      for file in main.zsh install.zsh uninstall.zsh version.zsh help.zsh README.md; do
        z.file.read path="$dir/prepared/$file"
        z.t.expect.reply "$file"
      done

      z.file.read path="$dir/prepared/lib/value"
      z.t.expect.reply core

      z.dir.exists "$dir/prepared/test"
      z.t.expect.status.is.true

      z.dir.not.exists "$dir/prepared/mod"
      z.t.expect.status.is.true

      z.dir.remove path=/tmp/z_t/update_core
    }
  }

  z.t.context "source引数がない場合"; {
    z.t.it "作業先を作らず失敗する"; {
      z.update.core._copy dir=/tmp/z_t/update_core_absent

      z.t.expect.status.is.false

      z.dir.not.exists /tmp/z_t/update_core_absent
      z.t.expect.status.is.true
    }
  }

  z.t.context "dir引数がない場合"; {
    z.t.it "失敗する"; {
      z.update.core._copy source=/tmp/source

      z.t.expect.status.is.false
    }
  }

  z.t.context "配布元のtest directoryがない場合"; {
    z.t.it "コピーの失敗を返す"; {
      local dir=/tmp/z_t/update_core/missing_directory
      z.dir.make path="$dir/source/lib"

      z.update.core._copy source="$dir/source" dir="$dir/prepared" 2>/dev/null
      local copy_status=$?

      z.t.expect "$copy_status" 1

      z.dir.remove path=/tmp/z_t/update_core
    }
  }

  z.t.context "必須fileがない場合"; {
    z.t.it "コピーの失敗を返す"; {
      local dir=/tmp/z_t/update_core/missing_file
      z.dir.make path="$dir/source/lib"
      z.dir.make path="$dir/source/test"
      z.file.write path="$dir/source/main.zsh" content=main

      z.update.core._copy source="$dir/source" dir="$dir/prepared" 2>/dev/null
      local copy_status=$?

      z.t.expect "$copy_status" 1

      z.dir.remove path=/tmp/z_t/update_core
    }
  }

  z.t.context "コピー先がすでにある場合"; {
    z.t.it "既存dataを上書きしない"; {
      local dir=/tmp/z_t/update_core/existing
      z.dir.make path="$dir/prepared"
      z.file.write path="$dir/prepared/value" content=original

      z.update.core._copy source="$dir/source" dir="$dir/prepared"
      local copy_status=$?

      z.t.expect "$copy_status" 1

      z.file.read path="$dir/prepared/value"
      z.t.expect.reply original

      z.dir.remove path=/tmp/z_t/update_core
    }
  }

  z.t.context "cpに失敗した場合"; {
    z.t.it "失敗を返して配布元は変更しない"; {
      local dir=/tmp/z_t/update_core/copy_failure
      z.dir.make path="$dir/source/lib"
      z.dir.make path="$dir/source/test"

      for file in main.zsh install.zsh uninstall.zsh version.zsh help.zsh README.md; do
        z.file.write path="$dir/source/$file" content="$file"
      done

      z.t.mock name=cp behavior="return 1"

      z.update.core._copy source="$dir/source" dir="$dir/prepared"
      local copy_status=$?

      z.t.expect "$copy_status" 1

      z.file.read path="$dir/source/main.zsh"
      z.t.expect.reply main.zsh

      z.dir.remove path=/tmp/z_t/update_core
    }
  }

}

