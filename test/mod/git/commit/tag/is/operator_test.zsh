source ${z_main}

z.t.describe "z.git.commit.tag.is.valid"; {
  z.t.context "有効なタグが渡された場合"; {
    z.t.it "trueを返す"; {
      z.t.mock name="z.git.commit.tag.list" behavior="z.return 'feat fix docs'"

      z.git.commit.tag.is.valid "feat"

      z.t.expect.status.is.true
    }
  }

  z.t.context "無効なタグが渡された場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.io.line"
      z.t.mock name="z.git.commit.help"
      z.t.mock name="z.git.commit.tag.list" behavior="z.return 'feat fix docs'"

      z.git.commit.tag.is.valid "invalid_tag"

      z.t.expect.status.is.false
    }
  }
}
