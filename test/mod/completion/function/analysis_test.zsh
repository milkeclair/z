source ${z_main}

z.t.describe "z.completion.function._candidates"; {
  z.t.context "z関数のprefixを指定した場合"; {
    z.t.it "prefixに一致する関数を返す"; {
      z_completion_function_names=(z.arg.get z.arg.named z.file.read) # zls: ignore

      z.completion.function._candidates z.arg.

      z.t.expect.reply.includes "z.arg.named"
    }
  }

  z.t.context "z.を指定した場合"; {
    z.t.it "直下のnamespaceを重複なく返す"; {
      z_completion_function_names=(z.str z.str.split z.str.color.red z.file.read z.file.write)

      z.completion.function._candidates z.

      z.t.expect.reply $'z.str.\nz.file.'
    }
  }

  z.t.context "z.でprivate関数しかないnamespaceがある場合"; {
    z.t.it "public関数を持つnamespaceだけを返す"; {
      z_completion_function_names=(z.str.split z.hidden._helper z.other)

      z.completion.function._candidates z.

      z.t.expect.reply z.str.
    }
  }

  z.t.context "z.str.を指定した場合"; {
    z.t.it "深い階層も含めてstr配下の関数を返す"; {
      z_completion_function_names=(z.str.split z.str.color.red z.str.color.rgb.hex z.file.read)

      z.completion.function._candidates z.str.

      z.t.expect.reply $'z.str.split\nz.str.color.red\nz.str.color.rgb.hex'
    }
  }

  z.t.context "z.str.color.を指定した場合"; {
    z.t.it "深い階層も含めてcolor配下の関数を返す"; {
      z_completion_function_names=(z.str.split z.str.color.red z.str.color.rgb.hex)

      z.completion.function._candidates z.str.color.

      z.t.expect.reply $'z.str.color.red\nz.str.color.rgb.hex'
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
