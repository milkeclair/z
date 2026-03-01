source ${z_main}

z.t.describe "z.git.c"; {
  z.t.context "呼び出した場合"; {
    z.t.it "z.git.commitを呼び出す"; {
      z.t.mock name="z.git.commit"

      z.git.c "feat" "commit message"

      z.t.mock.result
      z.t.expect.reply.is.arr "feat" "commit message"
    }
  }
}

z.t.describe "z.git.c.r"; {
  z.t.context "呼び出した場合"; {
    z.t.it "z.git.commit.tddをredサイクルで呼び出す"; {
      z.t.mock name="z.git.commit.tdd"

      z.git.c.r "feat" "commit message"

      z.t.mock.result
      z.t.expect.reply.is.arr "red" "feat" "commit message"
    }
  }
}

z.t.describe "z.git.c.g"; {
  z.t.context "呼び出した場合"; {
    z.t.it "z.git.commit.tddをgreenサイクルで呼び出す"; {
      z.t.mock name="z.git.commit.tdd"

      z.git.c.g "feat" "commit message"

      z.t.mock.result
      z.t.expect.reply.is.arr "green" "feat" "commit message"
    }
  }
}

z.t.describe "z.git.commit"; {
  z.t.context "引数が足りない場合"; {
    z.t.it "z.git.commit.helpを呼び出す"; {
      z.t.mock name="z.io.line"
      z.t.mock name="z.git.commit.help" behavior="z.io called"

      local result=$(z.git.commit "feat") # zls: ignore

      z.t.expect $result "called"
    }
  }

  z.t.context "タグが無効な場合"; {
    z.t.it "z.git.commit.helpを呼び出す"; {
      z.t.mock name="z.io.line"
      z.t.mock name="z.git.commit.help" behavior="z.io called"

      local result=$(z.git.commit "invalid" "message")

      z.t.expect $result "called"
    }
  }

  z.t.context "引数が有効な場合"; {
    z.t.it "z.git.commit.with_committerを呼び出す"; {
      z.t.mock name="z.git.commit.with_committer"

      z.git.commit "feat" "commit message" -ca

      z.t.mock.result
      z.t.expect.reply.is.arr "feat: commit message" "-ca"
    }
  }

  z.t.context "チケット番号が渡された場合"; {
    z.t.it "コミットメッセージにチケット番号を含める"; {
      z.t.mock name="z.git.commit.with_committer"

      z.git.commit "feat" "commit message" "TICKET-123" -ca

      z.t.mock.result
      z.t.expect.reply.is.arr "feat: #TICKET-123 commit message" "-ca"
    }
  }

  z.t.context "チケット番号がなく、-ntオプションがない場合"; {
    z.t.it "コミットメッセージに現在のブランチのチケット番号を含める"; {
      z.t.mock name="z.git.branch.current.get" behavior="z.return branch-456"
      z.t.mock name="z.git.commit.with_committer"

      z.git.commit "feat" "commit message"

      z.t.mock.result
      z.t.expect.reply.is.arr "feat: #456 commit message"
    }
  }
}

z.t.describe "z.git.commit.tdd"; {
  z.t.context "引数が足りない場合"; {
    z.t.it "z.git.commit.helpを呼び出す"; {
      z.t.mock name="z.io.line"
      z.t.mock name="z.git.commit.help" behavior="z.io called"

      local result=$(z.git.commit.tdd "red" "feat") # zls: ignore

      z.t.expect $result "called"
    }
  }

  z.t.context "サイクルが無効な場合"; {
    z.t.it "z.git.commit.helpを呼び出す"; {
      z.t.mock name="z.io.line"
      z.t.mock name="z.git.commit.help" behavior="z.io called"

      local result=$(z.git.commit.tdd "invalid" "feat" "message")

      z.t.expect $result "called"
    }
  }

  z.t.context "タグが無効な場合"; {
    z.t.it "z.git.commit.helpを呼び出す"; {
      z.t.mock name="z.io.line"
      z.t.mock name="z.git.commit.help" behavior="z.io called"

      local result=$(z.git.commit.tdd "red" "invalid" "message")

      z.t.expect $result "called"
    }
  }

  z.t.context "引数が有効な場合"; {
    z.t.it "z.git.commit.with_committerを呼び出す"; {
      z.t.mock name="z.git.commit.with_committer"

      z.git.commit.tdd "red" "feat" "commit message" -ca

      z.t.mock.result
      z.t.expect.reply.is.arr "feat: [red] commit message" "-ca"
    }
  }

  z.t.context "チケット番号が渡された場合"; {
    z.t.it "コミットメッセージにチケット番号を含める"; {
      z.t.mock name="z.git.commit.with_committer"

      z.git.commit.tdd "red" "feat" "commit message" "TICKET-123" -ca

      z.t.mock.result
      z.t.expect.reply.is.arr "feat: #TICKET-123 [red] commit message" "-ca"
    }
  }

  z.t.context "チケット番号がなく、-ntオプションがない場合"; {
    z.t.it "コミットメッセージに現在のブランチのチケット番号を含める"; {
      z.t.mock name="z.git.branch.current.get" behavior="z.return branch-456"
      z.t.mock name="z.git.commit.with_committer"

      z.git.commit.tdd "red" "feat" "commit message"

      z.t.mock.result
      z.t.expect.reply.is.arr "feat: #456 [red] commit message"
    }
  }
}

z.t.describe "z.git.commit.with_committer"; {
  z.t.context "呼び出した場合"; {
    z.t.it "git commitコマンドを正しい引数で呼び出す"; {
      z.t.mock name="z.git.commit.help.committer"
      z.t.mock name="git"

      z.git.commit.with_committer "feat: commit message" -ca

      z.t.mock.result
      z.t.expect.reply "commit -m feat: commit message --amend"
    }
  }
}

z.t.describe "z.git.commit.help"; {
  z.t.context "呼び出した場合"; {
    z.t.it "コミットのヘルプを表示する"; {
      local result=$(z.git.commit.help)

      z.t.expect.includes $result "commit:   z.git.c [tag] message ?[ticket] ?[-nt|-ca|-ae]"
    }
  }
}
