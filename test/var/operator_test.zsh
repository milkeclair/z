source ${z_main}

z.t.describe "z.var.exists"; {
  z.t.context "変数が存在しない場合"; {
    z.t.it "falseを返す"; {
      unset TEST_VAR_NON_EXISTENT

      z.var.exists TEST_VAR_NON_EXISTENT

      z.t.expect.status false
    }
  }

  z.t.context "変数が存在する場合"; {
    z.t.it "trueを返す"; {
      local TEST_VAR_EXISTENT="Hello, World!"

      z.var.exists TEST_VAR_EXISTENT

      z.t.expect.status true
    }
  }
}
