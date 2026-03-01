source ${z_main}

z.t.describe "z.git.user.set"; {
  z.t.context "呼び出した場合"; {
    z.t.it "z.git.user.set.localを呼び出す"; {
      z.t.mock name="z.git.user.set.local"

      z.git.user.set "Alice" "alice@example.com"

      z.t.mock.result
      z.t.expect.reply.is.arr "Alice" "alice@example.com"
    }
  }
}

z.t.describe "z.git.user.set.local"; {
  z.t.context "user.nameとuser.emailの両方が提供された場合"; {
    z.t.it "git config --local user.nameとuser.emailを実行する"; {
      z.t.mock name="z.io"
      z.t.mock name="git"

      z.git.user.set.local "Alice" "alice@example.com"

      z.t.mock.result name="git"
      z.t.expect.reply.is.arr \
        "config --local user.name Alice" \
        "config --local user.email alice@example.com"
    }
  }
}

z.t.describe "z.git.user.set.global"; {
  z.t.context "user.nameとuser.emailの両方が提供された場合"; {
    z.t.it "git config --global user.nameとuser.emailを実行する"; {
      z.t.mock name="z.io"
      z.t.mock name="git"

      z.git.user.set.global "Alice" "alice@example.com"

      z.t.mock.result name="git"
      z.t.expect.reply.is.arr \
        "config --global user.name Alice" \
        "config --global user.email alice@example.com"
    }
  }
}
