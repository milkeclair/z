source ${z_main}

z.t.describe "z.perm"; {
  z.t.context "modeが渡された場合"; {
    z.t.it "指定されたmodeに変更する"; {
      local file=/tmp/z_t/perm_mode.txt
      z.dir.make path=${file:h}
      z.file.write path=$file content="content"

      z.perm path=$file mode=600
      z.t.expect.status.is.true
      local mode=$(stat -c "%a" $file)

      z.t.expect $mode 600
    }
  }

  z.t.context "mode_owner, mode_group, mode_otherが渡された場合"; {
    z.t.it "指定された権限からmodeを組み立てて変更する"; {
      local file=/tmp/z_t/perm_named_mode.txt
      z.dir.make path=${file:h}
      z.file.write path=$file content="content"

      z.perm \
        path=$file \
        mode_owner=read,write,execute \
        mode_group=read,none,execute \
        mode_other=none,none,none
      z.t.expect.status.is.true
      local mode=$(stat -c "%a" $file)

      z.t.expect $mode 750
    }
  }

  z.t.context "ownerとgroupが渡された場合"; {
    z.t.it "所有者とグループを適用する"; {
      local file=/tmp/z_t/perm_owner.txt
      z.dir.make path=${file:h}
      z.file.write path=$file content="content"
      local owner=$(id -un)
      local group=$(id -gn)

      z.perm path=$file owner=$owner group=$group
      z.t.expect.status.is.true
      local actual_owner=$(stat -c "%U" $file)
      local actual_group=$(stat -c "%G" $file)

      z.t.expect $actual_owner $owner
      z.t.expect $actual_group $group
    }
  }

  z.t.context "pathが渡されない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.io.error"

      z.perm mode=600 # zls: ignore
      z.t.expect.status.is.false skip_unmock=true

      z.t.mock.result
      z.t.expect.reply "path is required"
    }
  }
}

z.t.describe "z.perm.dir"; {
  z.t.context "ディレクトリが渡された場合"; {
    z.t.it "配下も含めてmodeを変更する"; {
      local dir=/tmp/z_t/perm_dir
      local file=$dir/nested/file.txt
      z.dir.make path=${file:h}
      z.file.write path=$file content="content"

      z.perm.dir path=$dir mode=700
      z.t.expect.status.is.true
      local dir_mode=$(stat -c "%a" $dir)
      local file_mode=$(stat -c "%a" $file)

      z.t.expect $dir_mode 700
      z.t.expect $file_mode 700
    }
  }

  z.t.context "ownerとgroupが渡された場合"; {
    z.t.it "配下も含めて所有者とグループを適用する"; {
      local dir=/tmp/z_t/perm_dir_owner
      local file=$dir/nested/file.txt
      z.dir.make path=${file:h}
      z.file.write path=$file content="content"
      local owner=$(id -un)
      local group=$(id -gn)

      z.perm.dir path=$dir owner=$owner group=$group
      z.t.expect.status.is.true
      local dir_owner=$(stat -c "%U" $dir)
      local dir_group=$(stat -c "%G" $dir)
      local file_owner=$(stat -c "%U" $file)
      local file_group=$(stat -c "%G" $file)

      z.t.expect $dir_owner $owner
      z.t.expect $dir_group $group
      z.t.expect $file_owner $owner
      z.t.expect $file_group $group
    }
  }

  z.t.context "pathが渡されない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.io.error"

      z.perm.dir mode=700 # zls: ignore
      z.t.expect.status.is.false skip_unmock=true

      z.t.mock.result
      z.t.expect.reply "path is required"
    }
  }
}

z.t.describe "z.perm._apply"; {
  z.t.context "recursiveがfalseの場合"; {
    z.t.it "指定されたpathだけにmodeを適用する"; {
      local dir=/tmp/z_t/perm_apply
      local file=$dir/nested/file.txt
      z.dir.make path=${file:h}
      z.file.write path=$file content="content"

      z.perm._apply recursive=false path=$dir mode=700
      z.t.expect.status.is.true
      local dir_mode=$(stat -c "%a" $dir)
      local file_mode=$(stat -c "%a" $file)

      z.t.expect $dir_mode 700
      z.t.expect.not $file_mode 700
    }
  }

  z.t.context "recursiveがtrueの場合"; {
    z.t.it "配下も含めてmodeを適用する"; {
      local dir=/tmp/z_t/perm_apply_recursive
      local file=$dir/nested/file.txt
      z.dir.make path=${file:h}
      z.file.write path=$file content="content"

      z.perm._apply recursive=true path=$dir mode=701
      z.t.expect.status.is.true
      local dir_mode=$(stat -c "%a" $dir)
      local file_mode=$(stat -c "%a" $file)

      z.t.expect $dir_mode 701
      z.t.expect $file_mode 701
    }
  }

  z.t.context "ownerとgroupが渡された場合"; {
    z.t.it "所有者とグループを適用する"; {
      local file=/tmp/z_t/perm_apply_owner.txt
      z.dir.make path=${file:h}
      z.file.write path=$file content="content"
      local owner=$(id -un)
      local group=$(id -gn)

      z.perm._apply path=$file owner=$owner group=$group
      z.t.expect.status.is.true
      local actual_owner=$(stat -c "%U" $file)
      local actual_group=$(stat -c "%G" $file)

      z.t.expect $actual_owner $owner
      z.t.expect $actual_group $group
    }
  }

  z.t.context "pathが渡されない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.io.error"

      z.perm._apply mode=600 # zls: ignore
      z.t.expect.status.is.false skip_unmock=true

      z.t.mock.result
      z.t.expect.reply "path is required"
    }
  }
}

z.t.describe "z.perm._owner_spec"; {
  z.t.context "ownerとgroupが渡された場合"; {
    z.t.it "owner:groupを返す"; {
      z.perm._owner_spec owner=user group=group

      z.t.expect.reply "user:group"
    }
  }

  z.t.context "ownerだけが渡された場合"; {
    z.t.it "ownerを返す"; {
      z.perm._owner_spec owner=user

      z.t.expect.reply "user"
    }
  }

  z.t.context "groupだけが渡された場合"; {
    z.t.it ":groupを返す"; {
      z.perm._owner_spec group=group

      z.t.expect.reply ":group"
    }
  }

  z.t.context "ownerもgroupも渡されない場合"; {
    z.t.it "falseを返す"; {
      z.perm._owner_spec

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.perm._mode"; {
  z.t.context "modeが渡された場合"; {
    z.t.it "modeをそのまま返す"; {
      z.perm._mode mode=640

      z.t.expect.reply 640
    }
  }

  z.t.context "modeの詳細指定が渡された場合"; {
    z.t.it "数値modeに変換する"; {
      z.perm._mode \
        mode_owner=read,write,none \
        mode_group=read,none,none \
        mode_other=none,none,none

      z.t.expect.reply 640
    }
  }

  z.t.context "modeが渡されない場合"; {
    z.t.it "falseを返す"; {
      z.perm._mode

      z.t.expect.status.is.false
    }
  }

  z.t.context "不正な権限が渡された場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.io.error"

      z.perm._mode mode_owner=unknown
      z.t.expect.status.is.false skip_unmock=true

      z.t.mock.result
      z.t.expect.reply "invalid permission: unknown"
    }
  }
}

z.t.describe "z.perm._mode_digit"; {
  z.t.context "read, write, executeが渡された場合"; {
    z.t.it "7を返す"; {
      z.perm._mode_digit read,write,execute

      z.t.expect.reply 7
    }
  }

  z.t.context "read, write, noneが渡された場合"; {
    z.t.it "6を返す"; {
      z.perm._mode_digit read,write,none

      z.t.expect.reply 6
    }
  }

  z.t.context "read, none, executeが渡された場合"; {
    z.t.it "5を返す"; {
      z.perm._mode_digit read,none,execute

      z.t.expect.reply 5
    }
  }

  z.t.context "noneだけが渡された場合"; {
    z.t.it "0を返す"; {
      z.perm._mode_digit none,none,none

      z.t.expect.reply 0
    }
  }

  z.t.context "不正な権限が渡された場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.io.error"

      z.perm._mode_digit read,unknown,none
      z.t.expect.status.is.false skip_unmock=true

      z.t.mock.result
      z.t.expect.reply "invalid permission: unknown"
    }
  }
}
