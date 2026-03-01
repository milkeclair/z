source ${z_main}

z.t.describe "z.git.merge"; {
  z.t.context "\$1が空の場合"; {
    z.t.it "エラーを返す"; {
      z.t.mock name="z.io.line"
      z.t.mock name="z.io.error"

      z.git.merge # zls: ignore

      z.t.expect.status.is.false
    }

    z.t.it "エラーメッセージを表示する"; {
      z.t.mock name="z.io.line"
      z.t.mock name="z.io.error"

      z.git.merge # zls: ignore

      z.t.mock.result
      z.t.expect.reply "Target branch is required for merging."
    }
  }

  z.t.context "作業ツリーが汚れている場合"; {
    z.t.it "エラーを返す"; {
      z.t.mock name="z.io.line"
      z.t.mock name="z.io.error"
      z.t.mock name="z.git.status.is.dirty" behavior="return 0"

      z.git.merge main

      z.t.expect.status.is.false
    }

    z.t.it "エラーメッセージを表示する"; {
      z.t.mock name="z.io.line"
      z.t.mock name="z.io.error"
      z.t.mock name="z.git.status.is.dirty" behavior="return 0"

      z.git.merge main

      z.t.mock.result name="z.io.error"
      z.t.expect.reply "You have uncommitted changes. Please commit or stash them before merging."
    }
  }

  z.t.context "正常にマージできる場合"; {
    z.t.it "z.git.fetchを呼び出す"; {
      z.t.mock name="git"
      z.t.mock name="z.git.fetch" behavior="z.return called"

      z.git.merge main

      z.t.expect.reply "called"
    }

    z.t.it "git mergeコマンドを呼び出す"; {
      z.t.mock name="z.git.status.is.dirty" behavior="return 1"
      z.t.mock name="z.git.fetch"
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "merge main"; then
          z.return called
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.merge main

      z.t.expect.reply "called"
    }
  }
}
