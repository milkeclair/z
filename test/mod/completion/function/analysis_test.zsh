source ${z_main}

z.t.describe "z.completion.function._candidates"; {
  z.t.context "z関数のprefixを指定した場合"; {
    z.t.it "prefixに一致する関数を返す"; {
      z_completion_function_names=(z.arg.get z.arg.named z.file.read) # zls: ignore

      z.completion.function._candidates z.arg.

      z.t.expect.reply.includes "z.arg.named"
    }
  }

  z.t.context "function name cacheが空の場合"; {
    z.t.it "falseを返す"; {
      z_completion_function_names=()

      z.completion.function._candidates z.arg.

      z.t.expect.status.is.false
    }
  }

  z.t.context "prefixに一致する候補がない場合"; {
    z.t.it "falseを返す"; {
      z_completion_function_names=(z.file.read z.file.write) # zls: ignore

      z.completion.function._candidates z.arg.

      z.t.expect.status.is.false
    }
  }

  z.t.context "private関数がprefixに一致する場合"; {
    z.t.it "候補に含めない"; {
      z_completion_function_names=(z.wtproxy.start z.wtproxy.start._daemon z.wtproxy._state.init)

      z.completion.function._candidates z.wtproxy
      local candidates=$REPLY

      z.t.expect.includes "$candidates" "z.wtproxy.start"
      z.t.expect.excludes "$candidates" "z.wtproxy.start._daemon"
      z.t.expect.excludes "$candidates" "z.wtproxy._state.init"
    }
  }

  z.t.context "prefixを指定した場合"; {
    z.t.it "publicだけを返す"; {
      z_completion_function_names=(z.completion.enable z.completion.cache._build z.completion.function._candidates z.completion.complete._run)

      z.completion.function._candidates z.completion. # zls: ignore
      local candidates=$REPLY

      z.t.expect.includes "$candidates" "z.completion.enable"
      z.t.expect.excludes "$candidates" "z.completion.cache._build"
      z.t.expect.excludes "$candidates" "z.completion.function._candidates"
      z.t.expect.excludes "$candidates" "z.completion.complete._run"
    }
  }
}
