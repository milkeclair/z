source ${z_main}

z.t.describe "z.git.commit._arg.extract.opts"; {
  z.t.context "opts_countとopts_1~opts_nが渡された場合"; {
    z.t.it "opts_1~opts_nを配列で返す"; {
      z.git.commit._arg.extract.opts \
        opts_count 3 \
        opts_1 "-m" \
        opts_2 "commit message" \
        opts_3 "--amend" \
        opts_4 "extra_option" # should be ignored

      z.t.expect.reply.is.arr "-m" "commit message" "--amend"
    }
  }

  z.t.context "opts_countが0の場合"; {
    z.t.it "空配列を返す"; {
      z.git.commit._arg.extract.opts opts_count 0

      z.t.expect.reply.is.null
    }
  }
}
