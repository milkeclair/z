source ${z_main}

z.t.describe "z.group"; {
  z.t.context "グループ名を指定した場合"; {
    z.t.it "trueを返す"; {
      z.group "name"

      z.t.expect.status.true
    }

    z.t.it "REPLYを変更しない"; {
      REPLY="original"

      z.group "name"

      z.t.expect.reply "original"
    }
  }

  z.t.context "グループ名を指定しなかった場合"; {
    z.t.it "trueを返す"; {
      z.group

      z.t.expect.status.true
    }

    z.t.it "REPLYを変更しない"; {
      REPLY="original"

      z.t.expect.reply "original"
    }
  }
}

z.t.describe "z.guard"; {
  z.t.context "ガード節を指定した場合"; {
    z.t.it "trueを返す"; {
      z.guard "guard_name"

      z.t.expect.status.true
    }

    z.t.it "REPLYを変更しない"; {
      REPLY="original"

      z.guard "guard_name"

      z.t.expect.reply "original"
    }
  }

  z.t.context "ガード節を指定しなかった場合"; {
    z.t.it "trueを返す"; {
      z.guard

      z.t.expect.status.true
    }

    z.t.it "REPLYを変更しない"; {
      REPLY="original"

      z.guard

      z.t.expect.reply "original"
    }
  }
}
