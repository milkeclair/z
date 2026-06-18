source ${z_main}

z.t.describe "z.git.commit._arg.extract"; {
  z.t.context "オプション無しで引数が渡された場合"; {
    z.t.it "opts_countが0でtag, message, ticketを返す"; {
      z.git.commit._arg.extract "feat" "commit message"

      z.t.expect.reply.is.arr \
        "tag" "feat" \
        "message" "commit message" \
        "ticket" "" \
        "opts_count" 0
    }
  }

  z.t.context "オプションが渡された場合"; {
    z.t.it "opts_countとopts_1~opts_nを返す"; {
      z.git.commit._arg.extract "feat" "commit message" --amend --allow-empty

      z.t.expect.reply.is.arr \
        "tag" "feat" \
        "message" "commit message" \
        "ticket" "" \
        "opts_count" 2 \
        "opts_1" "--amend" \
        "opts_2" "--allow-empty"
    }
  }

  z.t.context "チケット番号が渡された場合"; {
    z.t.it "ticketにチケット番号を返す"; {
      z.git.commit._arg.extract "feat" "commit message" "TICKET-123"

      z.t.expect.reply.is.arr \
        "tag" "feat" \
        "message" "commit message" \
        "ticket" "TICKET-123" \
        "opts_count" 0
    }
  }
}
