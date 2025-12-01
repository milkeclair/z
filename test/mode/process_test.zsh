source ${z_main}

z.t.describe "z.mode"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "モードに入る"; {
      (z.io.null z.mode git <<< "q")

      z.t.expect.status.is.false
    }

    z.t.it "引数を接頭辞としてコマンドを実行する"; {
      z.t.mock name=z.io
      z.t.mock name=z.io.oneline

      z.mode z.io <<< "Hello"$'\n'"q"

      z.t.mock.result name=z.io
      z.t.expect.reply "Hello"
    }

    z.t.it "splitを指定した場合はそれを間に入れる"; {
      z.t.mock name=z.io.oneline
      z.t.mock name=z.io.line

      z.mode z.io split=. <<< "line indent=1 'Hello'"$'\n'"q"

      z.t.mock.result name=z.io.line
      z.t.expect.reply "indent=1 Hello"
    }

    z.t.it "splitを指定しない場合はスペースを空ける"; {
      local output=$(z.mode git <<< "version"$'\n'"q")

      z.t.expect.includes $output "git version"
    }
  }

  z.t.context "qを入力した場合"; {
    z.t.it "終了ステータス1を返す"; {
      (z.io.null z.mode git <<< "q")

      z.t.expect.status 1
    }
  }

  z.t.context "quitを入力した場合"; {
    z.t.it "終了ステータス1を返す"; {
      (z.io.null z.mode git <<< "quit")

      z.t.expect.status 1
    }
  }

  z.t.context "exitを入力した場合"; {
    z.t.it "終了ステータス1を返す"; {
      (z.io.null z.mode git <<< "exit")

      z.t.expect.status 1
    }
  }
}
