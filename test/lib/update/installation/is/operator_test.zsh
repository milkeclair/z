source "$z_main"

z.t.describe "z.update.installation.is._valid"; {
  z.t.context "本体のディレクトリとmainがある場合"; {
    z.t.it "更新可能と判定する"; {
      local dir=/tmp/z_t/update_valid/installed
      z.dir.remove path=/tmp/z_t/update_valid
      z.dir.make path="$dir/lib"
      z.file.write path="$dir/main.zsh" content=main

      z.update.installation.is._valid dir="$dir"

      z.t.expect.status.is.true

      z.dir.remove path=/tmp/z_t/update_valid
    }
  }

  z.t.context "dir引数がない場合"; {
    z.t.it "失敗する"; {
      z.update.installation.is._valid # zls: ignore missing-named-argument

      z.t.expect.status.is.false
    }
  }

  z.t.context "mainがない場合"; {
    z.t.it "失敗する"; {
      local dir=/tmp/z_t/update_valid/missing_main
      z.dir.make path="$dir/lib"

      z.update.installation.is._valid dir="$dir"

      z.t.expect.status.is.false

      z.dir.remove path=/tmp/z_t/update_valid
    }
  }

  z.t.context "libがない場合"; {
    z.t.it "失敗する"; {
      local dir=/tmp/z_t/update_valid/missing_lib
      z.dir.make path="$dir"
      z.file.write path="$dir/main.zsh" content=main

      z.update.installation.is._valid dir="$dir"

      z.t.expect.status.is.false

      z.dir.remove path=/tmp/z_t/update_valid
    }
  }

  z.t.context "git directoryがある場合"; {
    z.t.it "checkoutを除外する"; {
      local dir=/tmp/z_t/update_valid/git_directory
      z.dir.make path="$dir/lib"
      z.dir.make path="$dir/.git"
      z.file.write path="$dir/main.zsh" content=main

      z.update.installation.is._valid dir="$dir"

      z.t.expect.status.is.false

      z.dir.remove path=/tmp/z_t/update_valid
    }
  }

  z.t.context "git fileがある場合"; {
    z.t.it "linked worktreeを除外する"; {
      local dir=/tmp/z_t/update_valid/git_file
      z.dir.make path="$dir/lib"
      z.file.write path="$dir/main.zsh" content=main
      z.file.write path="$dir/.git" content="gitdir: elsewhere"

      z.update.installation.is._valid dir="$dir"

      z.t.expect.status.is.false

      z.dir.remove path=/tmp/z_t/update_valid
    }
  }

  z.t.context "rootまたはHOMEを指定した場合"; {
    z.t.it "変更対象にしない"; {
      z.update.installation.is._valid dir=/

      z.t.expect.status.is.false

      z.update.installation.is._valid dir="$HOME"

      z.t.expect.status.is.false
    }
  }

}

