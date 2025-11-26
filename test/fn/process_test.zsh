source ${z_main}

z.t.describe "z.fn"; {
  z.t.context "nameとbodyを指定した場合"; {
    z.t.it "関数が登録される"; {
      z.t.mock name="z.io"
      local name="z_t_fn_$(uuidgen)"
      local body='z.io "Hello, World!"'

      z.fn $name $body
      z.fn.call $name

      z.t.mock.result
      z.t.expect.reply "Hello, World!"
    }

    z.t.it "定義元のパスが保存される"; {
      local name="z_t_fn_$(uuidgen)"
      local body='z.io "Hello, World!"'

      z.fn $name $body

      z.t.expect $z_fn_source[$name] $PWD
    }

    z.t.it "同名の関数は登録できない"; {
      z.t.mock name="z.io.error"
      local name="z_t_fn_$(uuidgen)"
      local body='z.io "Hello, World!"'

      z.fn $name $body
      z.fn $name $body

      z.t.mock.result
      z.t.expect.reply "Function $name already exists."
    }
  }

  z.t.context "削除後"; {
    z.t.it "再登録できる"; {
      z.t.mock name="z.io"
      local name="z_t_fn_$(uuidgen)"

      z.fn $name 'z.io "before"'
      z.fn.delete $name
      z.fn $name 'z.io "after"'

      z.fn.call $name

      z.t.mock.result
      z.t.expect.reply "after"
    }
  }
}

z.t.describe "z.fn.call"; {
  z.t.context "登録済みの関数名を指定した場合"; {
    z.t.it "関数が実行される"; {
      z.t.mock name="z.io"
      local name="z_t_fn_$(uuidgen)"
      local body='z.io "Hello, World!"'

      z.fn $name $body
      z.fn.call $name

      z.t.mock.result
      z.t.expect.reply "Hello, World!"
    }
  }

  z.t.context "未登録の関数名を指定した場合"; {
    z.t.it "エラーになる"; {
      z.t.mock name="z.io.error"
      local name="z_t_fn_$(uuidgen)"

      z.fn.call $name

      z.t.mock.result
      z.t.expect.reply "Function $name does not exist."
    }
  }
}

z.t.describe "z.fn.delete"; {
  z.t.context "登録済みの関数名を指定した場合"; {
    z.t.it "関数が削除される"; {
      z.t.mock name="z.io.error"
      local name="z_t_fn_$(uuidgen)"
      local body='z.io "Hello, World!"'

      z.fn $name $body
      z.fn.delete $name
      z.fn.call $name

      z.t.mock.result
      z.t.expect.reply "Function $name does not exist."
    }
  }

  z.t.context "未登録の関数名を指定した場合"; {
    z.t.it "エラーになる"; {
      z.t.mock name="z.io.error"
      local name="z_t_fn_$(uuidgen)"

      z.fn.delete $name

      z.t.mock.result
      z.t.expect.reply "Function $name does not exist."
    }
  }
}

z.t.describe "z.fn.delete_all"; {
  z.t.context "複数の関数が登録されている場合"; {
    z.t.it "全ての関数が削除される"; {
      z.t.mock name="z.io.error"
      local name1="z_t_fn_$(uuidgen)"
      local body1='z.io "Function 1"'
      local name2="z_t_fn_$(uuidgen)"
      local body2='z.io "Function 2"'

      z.fn $name1 $body1
      z.fn $name2 $body2
      z.fn.delete_all
      z.fn.call $name1
      z.fn.call $name2

      z.t.mock.result
      z.t.expect.reply "Function $name1 does not exist. Function $name2 does not exist."
    }
  }
}

z.t.describe "z.fn.edit"; {
  z.t.context "登録済みの関数名と新しい定義を指定した場合"; {
    z.t.it "関数が更新される"; {
      z.t.mock name="z.io"
      local name="z_t_fn_$(uuidgen)"
      local body1='z.io "Before Edit"'
      local body2='z.io "After Edit"'

      z.fn $name $body1
      z.fn.edit $name $body2
      z.fn.call $name

      z.t.mock.result
      z.t.expect.reply "After Edit"
    }
  }

  z.t.context "未登録の関数名を指定した場合"; {
    z.t.it "エラーになる"; {
      z.t.mock name="z.io.error"
      local name="z_t_fn_$(uuidgen)"
      local body='z.io "Hello, World!"'

      z.fn.edit $name $body

      z.t.mock.result
      z.t.expect.reply "Function $name does not exist."
    }
  }
}

z.t.describe "z.fn._ensure_store"; {
  z.t.context "関数ストアが初期化されていない場合"; {
    z.t.it "連想配列が初期化される"; {
      unset z_fn_set
      unset z_fn_source

      z.fn._ensure_store

      z.t.expect ${(k)z_fn_set} ''
      z.t.expect ${(k)z_fn_source} ''
    }
  }

  z.t.context "関数ストアが初期化済みの場合"; {
    z.t.it "何もしない"; {
      typeset -gA z_fn_set
      typeset -gA z_fn_source
      z_fn_set["test"]="value"
      z_fn_source["test"]="/path/to/source"

      z.fn._ensure_store

      z.t.expect ${(v)z_fn_set["test"]} 'value'
      z.t.expect ${(v)z_fn_source["test"]} '/path/to/source'
    }
  }
}
