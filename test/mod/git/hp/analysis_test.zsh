source ${z_main}

z.t.describe "z.git.hp.ticket"; {
  z.t.context "現在のブランチ名にチケット番号が含まれている場合"; {
    z.t.it "チケット番号を返す"; {
      z.t.mock name="z.git.branch.current.get" behavior="z.return feature/some-description-123"

      z.git.hp.ticket

      z.t.expect.reply "123"
    }
  }

  z.t.context "現在のブランチ名にチケット番号が含まれていない場合"; {
    z.t.it "nullを返す"; {
      z.t.mock name="z.git.branch.current.get" behavior="z.return feature/some-description"

      z.git.hp.ticket

      z.t.expect.reply.is.null
    }
  }
}
