source ${z_main}

z.t.describe "z.git.mode"; {
  z.t.context "呼び出した場合"; {
    z.t.it "モードに入る"; {
      (z.io.null z.git.mode <<< "q")

      z.t.expect.status.is.false
    }

    z.t.it "引数を接頭辞としてコマンドを実行する"; {
      z.t.mock name=z.io.oneline
      z.t.mock name=z.git.add

      z.git.mode <<< "add file.txt"$'\n'"q"

      z.t.mock.result name=z.git.add
      z.t.expect.reply "file.txt"
    }
  }

  z.t.context "qを入力した場合"; {
    z.t.it "終了ステータス1を返す"; {
      (z.io.null z.git.mode <<< "q")

      z.t.expect.status 1
    }
  }

  z.t.context "quitを入力した場合"; {
    z.t.it "終了ステータス1を返す"; {
      (z.io.null z.git.mode <<< "quit")

      z.t.expect.status 1
    }
  }

  z.t.context "exitを入力した場合"; {
    z.t.it "終了ステータス1を返す"; {
      (z.io.null z.git.mode <<< "exit")

      z.t.expect.status 1
    }
  }
}
