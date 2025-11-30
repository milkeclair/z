source ${z_main}

z.t.describe "z.var.exists"; {
  z.t.context "変数に値が存在する場合"; {
    z.t.it "trueを返す"; {
      local TEST_VAR_EXISTENT="Hello, World!"

      z.var.exists TEST_VAR_EXISTENT

      z.t.expect.status true
      unset TEST_VAR_EXISTENT
    }
  }

  z.t.context "変数が宣言されている場合"; {
    z.t.it "trueを返す"; {
      declare TEST_VAR_DECLARED

      z.var.exists TEST_VAR_DECLARED

      z.t.expect.status true
      unset TEST_VAR_DECLARED
    }
  }

  z.t.context "変数が存在しない場合"; {
    z.t.it "falseを返す"; {
      unset TEST_VAR_NON_EXISTENT

      z.var.exists TEST_VAR_NON_EXISTENT

      z.t.expect.status false
    }
  }
}

z.t.describe "z.var.sets"; {
  z.t.context "変数に値が存在する場合"; {
    z.t.it "trueを返す"; {
      local TEST_VAR_EXISTENT="Hello, World!"

      z.var.sets TEST_VAR_EXISTENT

      z.t.expect.status true
      unset TEST_VAR_EXISTENT
    }
  }

  z.t.context "変数が宣言されている場合"; {
    z.t.it "falseを返す"; {
      declare TEST_VAR_DECLARED

      z.var.sets TEST_VAR_DECLARED

      z.t.expect.status false
      unset TEST_VAR_DECLARED
    }
  }

  z.t.context "変数が存在しない場合"; {
    z.t.it "falseを返す"; {
      unset TEST_VAR_NON_EXISTENT

      z.var.sets TEST_VAR_NON_EXISTENT

      z.t.expect.status false
    }
  }
}
