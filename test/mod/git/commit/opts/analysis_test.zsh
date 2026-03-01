source ${z_main}

z.t.describe "z.git.commit.opts.extract"; {
  z.t.context "有効なオプションが渡された場合"; {
    z.t.it "有効なオプションを配列で返す"; {
      z.git.commit.opts.extract -m "commit message" -ca -ae

      z.t.expect.reply.is.arr "--amend" "--allow-empty"
    }
  }

  z.t.context "無効なオプションが渡された場合"; {
    z.t.it "有効なオプションのみを配列で返す"; {
      z.git.commit.opts.extract -m "commit message" -invalid -ca

      z.t.expect.reply.is.arr "--amend"
    }
  }
}
