source ${z_main}

z.t.describe "z.fn.not.exists"; {
  z.t.context "未登録の関数名を指定した場合"; {
    z.t.it "trueが返る"; {
      local name="z_t_fn_$(uuidgen)"

      z.fn.not.exists $name

      z.t.expect.status.is.true
    }
  }

  z.t.context "登録済みの関数名を指定した場合"; {
    z.t.it "falseが返る"; {
      local name="z_t_fn_$(uuidgen)"
      local body='z.io "Hello, World!"'

      z.fn $name $body
      z.fn.not.exists $name

      z.t.expect.status.is.false
    }
  }
}
