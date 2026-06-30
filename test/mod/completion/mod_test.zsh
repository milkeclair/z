source ${z_main}

z.t.describe "z.completion mod"; {
  z.t.context "依存関係を確認する場合"; {
    z.t.it "jobに依存する"; {
      z.mod.dependencies completion
      local dependencies=($REPLY)

      z.arr.includes target=job "${dependencies[@]}"

      z.t.expect.status.is.true
    }
  }
}
