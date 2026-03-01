source ${z_main}

z.t.describe "z.git.user.set.args.is.enough"; {
  z.t.context "user.nameとuser.emailの両方が提供された場合"; {
    z.t.it "0を返す"; {
      z.git.user.set.arg.is.enough "Alice" "alice@example.com"

      z.t.expect.status.is.true
    }
  }

  z.t.context "user.nameが提供されなかった場合"; {
    z.t.it "エラーを返す"; {
      z.t.mock name="z.io"

      z.git.user.set.arg.is.enough "" "alice@example.com"

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result
      z.t.expect.reply "require user.name"
    }
  }

  z.t.context "user.emailが提供されなかった場合"; {
    z.t.it "エラーを返す"; {
      z.t.mock name="z.io"

      z.git.user.set.arg.is.enough "Alice" ""

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result
      z.t.expect.reply "require user.email"
    }
  }

  z.t.context "user.nameとuser.emailの両方が提供されなかった場合"; {
    z.t.it "エラーを返す"; {
      z.t.mock name="z.io"

      z.git.user.set.arg.is.enough "" ""

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result
      z.t.expect.reply.is.arr "require user.name" "require user.email"
    }
  }
}
