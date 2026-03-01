source ${z_main}

z.t.describe "z.git.commit.tdd.cycle.list"; {
  z.t.context "呼び出した場合"; {
    z.t.it "有効なコミットサイクルの配列を返す"; {
      z.git.commit.tdd.cycle.list

      z.t.expect.reply.is.arr "red" "green"
    }
  }
}
