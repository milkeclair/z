source ${z_main}

z.t.describe "z.var.get"; {
  z.t.context "変数が存在しない場合"; {
    z.t.it "nullを返す"; {
      unset TEST_VAR_NON_EXISTENT

      z.var.get TEST_VAR_NON_EXISTENT

      z.t.expect.reply.is.null
    }
  }

  z.t.context "変数が存在する場合"; {
    z.t.it "変数の値を返す"; {
      local TEST_VAR_EXISTENT="Hello, World!"

      z.var.get TEST_VAR_EXISTENT

      z.t.expect.reply "Hello, World!"
    }
  }

  z.t.context "変数が配列の場合"; {
    z.t.it "配列の値を返す"; {
      local TEST_VAR_ARRAY=("one" "two" "three")

      z.var.get TEST_VAR_ARRAY

      z.t.expect.reply "one two three"
    }
  }
}
