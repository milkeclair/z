source ${z_main}

z.t.describe "z.completion.cache.build.line.is._comment"; {
  z.t.context "comment行の場合"; {
    z.t.it "trueを返す"; {
      z.completion.cache.build.line.is._comment "# docs"

      z.t.expect.status.is.true
    }
  }

  z.t.context "comment行がindentされている場合"; {
    z.t.it "trueを返す"; {
      z.completion.cache.build.line.is._comment "  # docs"

      z.t.expect.status.is.true
    }
  }

  z.t.context "comment行ではない場合"; {
    z.t.it "falseを返す"; {
      z.completion.cache.build.line.is._comment "z.example.test() {"

      z.t.expect.status.is.false
    }
  }

  z.t.context "非comment行がindentされている場合"; {
    z.t.it "falseを返しREPLYに先頭空白を除去した行を残す"; {
      z.completion.cache.build.line.is._comment $'\t  z.example.test() {'
      local command_status=$? trimmed_line=$REPLY
      z.t.expect "$command_status" "1"
      z.t.expect "$trimmed_line" "z.example.test() {"
    }
  }
}
