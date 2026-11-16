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

  z.t.context "literalがtrueの場合"; {
    z.t.it "空要素と真偽値風の値を配列のまま返す"; {
      local input_args=("" "true" "null" "two words" "keep_empty=true")

      z.var.get input_args literal=true
      local result=("${REPLY[@]}")

      z.t.expect "${#result[@]}" 5
      z.t.expect "${result[1]}" ""
      z.t.expect "${result[2]}" "true"
      z.t.expect "${result[3]}" "null"
      z.t.expect "${result[4]}" "two words"
      z.t.expect "${result[5]}" "keep_empty=true"
    }
  }
  z.t.context "入力がREPLYの場合"; {
    z.t.it "名前付き引数を取得する前の値を返す"; {
      local REPLY="sentinel"

      z.var.get REPLY

      z.t.expect.reply "sentinel"
    }

    z.t.it "literal指定時も元の配列要素を保持する"; {
      local REPLY=("true" "" "two words")

      z.var.get REPLY literal=true
      local result=("${REPLY[@]}")

      z.t.expect "${#result[@]}" 3
      z.t.expect "${result[1]}" "true"
      z.t.expect "${result[2]}" ""
      z.t.expect "${result[3]}" "two words"
    }
  }

}
