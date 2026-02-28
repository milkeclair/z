source ${z_main}

z.t.describe "z.git.commit.msg.build"; {
  z.t.context "tag, messageを渡した場合"; {
    z.t.it "tagとmessageを組み合わせたコミットメッセージを返す"; {
      z.git.commit.msg.build tag="feat" message="add new feature"

      z.t.expect.reply "feat: add new feature"
    }
  }

  z.t.context "tag, message, ticketを渡した場合"; {
    z.t.it "tag, ticket, messageを組み合わせたコミットメッセージを返す"; {
      z.git.commit.msg.build tag="fix" message="fix bug" ticket="feat-123"

      z.t.expect.reply "fix: #feat-123 fix bug"
    }
  }

  z.t.context "tag, message, cycle"; {
    z.t.it "tag, cycle, messageを組み合わせたコミットメッセージを返す"; {
      z.git.commit.msg.build tag="refactor" message="refactor code" cycle="green"

      z.t.expect.reply "refactor: [green] refactor code"
    }
  }

  z.t.context "tag, message, ticket, cycleを渡した場合"; {
    z.t.it "tag, ticket, cycle, messageを組み合わせたコミットメッセージを返す"; {
      z.git.commit.msg.build tag="feat" message="add new feature" ticket="TICKET-123" cycle="red"

      z.t.expect.reply "feat: #TICKET-123 [red] add new feature"
    }
  }
}
