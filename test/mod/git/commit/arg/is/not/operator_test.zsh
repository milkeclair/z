source ${z_main}

z.t.describe "z.git.commit.arg.is.not.no_ticket"; {
  z.t.context "commit argsに-ntが含まれていない場合"; {
    z.t.it "trueを返す"; {
      z.git.commit.arg.is.not.no_ticket opts='-m "commit message"'

      z.t.expect.status.is.true
    }
  }

  z.t.context "commit argsに-ntが含まれている場合"; {
    z.t.it "falseを返す"; {
      z.git.commit.arg.is.not.no_ticket opts='-m "commit message" -nt'

      z.t.expect.status.is.false
    }
  }
}
