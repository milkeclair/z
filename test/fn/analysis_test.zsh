source ${z_main}

z.t.describe "z.fn.list"; {
  z.t.context "登録済みの関数がある場合"; {
    z.t.it "関数名と定義元パスが表示される"; {
      z.t.mock name="z.io"
      local name="z_t_fn_$(uuidgen)"
      local body='z.io "Hello, World!"'

      z.fn $name $body
      z.fn.list

      z.t.mock.result name="z.io"
      z.t.expect.reply.include "$name Defined in $PWD indent=1"
    }
  }

  z.t.context "登録済みの関数がない場合"; {
    z.t.it "何も表示されない"; {
      z.t.mock name="z.io"
      z.fn.delete_all

      z.fn.list

      z.t.mock.result name="z.io"
      z.t.expect.reply.null
    }
  }
}

z.t.describe "z.fn.show"; {
  z.t.context "登録済みの関数名を指定した場合"; {
    z.t.it "関数の定義が表示される"; {
      z.t.mock name="z.io"
      local name="z_t_fn_$(uuidgen)"
      local body='Hello, World!'

      z.fn $name $body
      z.fn.show $name

      z.t.mock.result name="z.io"
      local result=$REPLY
      z.t.expect.include "$result" "Defined in"
      z.t.expect.include "$result" $PWD
      z.t.expect.include "$result" 'Hello, World!'
    }
  }

  z.t.context "未登録の関数名を指定した場合"; {
    z.t.it "エラーメッセージが表示される"; {
      z.t.mock name="z.io.error"
      local name="z_t_fn_nonexistent_$(uuidgen)"

      z.fn.show $name

      z.t.mock.result name="z.io.error"
      z.t.expect.reply "Function $name does not exist."
    }
  }
}
