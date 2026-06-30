source ${z_main}

z.t.describe "z.job.precmd._register"; {
  z.t.context "未登録の場合"; {
    z.t.it "z.job.collectをprecmd_functionsへ登録する"; {
      local -a original_precmd_functions=("${precmd_functions[@]}")
      precmd_functions=()

      z.job.precmd._register

      z.arr.includes target=z.job.collect "${precmd_functions[@]}"
      z.t.expect.status.is.true
      precmd_functions=("${original_precmd_functions[@]}")
    }
  }

  z.t.context "すでに登録されている場合"; {
    z.t.it "重複登録しない"; {
      local -a original_precmd_functions=("${precmd_functions[@]}")
      precmd_functions=()

      z.job.precmd._register
      z.job.precmd._register

      z.arr.count "${precmd_functions[@]}"
      z.t.expect.reply 1
      precmd_functions=("${original_precmd_functions[@]}")
    }
  }

  z.t.context "add-zsh-hookが失敗した場合"; {
    z.t.it "falseを返す"; {
      local -a original_precmd_functions=("${precmd_functions[@]}")
      precmd_functions=()
      z.t.mock name="add-zsh-hook" behavior="return 1"

      z.job.precmd._register

      z.t.expect.status.is.false
      precmd_functions=("${original_precmd_functions[@]}")
    }
  }
}
