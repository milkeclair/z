source ${z_main}

z.t.describe "z.git.add"; {
  z.t.context ".を指定した場合"; {
    z.t.it "エラーを返す"; {
      z.t.mock name="z.io"

      z.git.add .

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result
      z.t.expect.reply 'Rejecting "git add ." command. Please specify the files to add explicitly.'
    }
  }

  z.t.context "ファイルを指定した場合"; {
    z.t.it "git addコマンドを実行する"; {
      z.t.mock name="git"

      z.git.add file1.txt file2.txt

      z.t.expect.status.is.true skip_unmock=true
      z.t.mock.result
      z.t.expect.reply "add file1.txt file2.txt"
    }
  }
}
