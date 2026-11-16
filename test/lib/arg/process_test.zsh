source ${z_main}

z.t.describe "z.arg.as"; {
  z.t.context "nameがエイリアスのいずれかに一致する場合"; {
    z.t.it "returnを返す"; {
      z.arg.as name=-h "as=-h|--help" return=0

      z.t.expect.reply 0
    }
  }

  z.t.context "nameがエイリアスのいずれかに一致し、第三引数がない場合"; {
    z.t.it "nullを返す"; {
      z.arg.as name=--help "as=-h|--help"

      z.t.expect.reply.is.null
    }
  }

  z.t.context "nameがエイリアスのいずれにも一致しない場合"; {
    z.t.it "nullを返す"; {
      z.arg.as name=--version "as=-h|--help" return=0

      z.t.expect.reply.is.null
    }
  }

  z.t.context "nameがエイリアスのいずれにも一致せず、第三引数がない場合"; {
    z.t.it "nullを返す"; {
      z.arg.as name=--help "as=-v|--version"

      z.t.expect.reply.is.null
    }
  }

  z.t.context "nameがnullの場合"; {
    z.t.it "nullを返す"; {
      z.arg.as "as=-h|--help" return=0 # zls: ignore

      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.arg.named"; {
  z.t.context "nameが指定されている場合"; {
    z.t.it "nameを返す"; {
      z.arg.named name name=hoge other=fuga

      z.t.expect.reply hoge
    }
  }

  z.t.context "nameを含む別の引数が指定されている場合"; {
    z.t.it "一致したものとして扱わない"; {
      z.arg.named name user_name=hoge default=default_value

      z.t.expect.reply default_value
    }
  }

  z.t.context "defaultを含む別の引数が指定されている場合"; {
    z.t.it "defaultとして扱わない"; {
      z.arg.named name name="" my_default=other default=default_value

      z.t.expect.reply default_value
    }
  }

  z.t.context "nameが指定されていない場合"; {
    z.t.it "nullを返す"; {
      z.arg.named # zls: ignore

      z.t.expect.reply.is.null
    }
  }

  z.t.context "指定した名前の引数がない場合"; {
    z.t.it "成功して空の値を返す"; {
      z.arg.named name other=fuga
      local result_code=$?
      local result_reply=$REPLY

      z.t.expect "$result_code" 0
      z.t.expect "$result_reply" ""
    }
  }

  z.t.context "defaultが指定されていて、値がない場合"; {
    z.t.it "デフォルト値を返す"; {
      z.arg.named name name="" other=fuga default=default_value

      z.t.expect.reply default_value
    }
  }

  z.t.context "defaultが指定されていて、値がある場合"; {
    z.t.it "指定された値を返す"; {
      z.arg.named name name=hoge other=fuga default=default_value

      z.t.expect.reply hoge
    }
  }

  z.t.context "重複した名前と後続のdefault指定がある場合"; {
    z.t.it "最初の名前付き値がnullなら最後のdefaultを使う"; {
      z.arg.named name name=null name=second default=first default=last
      z.t.expect.reply last
    }

    z.t.it "最初の名前付き値がfalseなら数値の1を返す"; {
      z.arg.named name name=false name=second default=last
      z.t.expect.reply 1
    }

    z.t.it "default自体を取得する場合も既存の既定値規約に従う"; {
      z.arg.named default default=first default=last
      z.t.expect.reply last
    }
  }

  z.t.context "名前に等号や括弧を含む場合"; {
    z.t.it "名前全体の接頭辞を除き、値の等号を保持する"; {
      z.arg.named "a=b" "a=b=value=tail" default=fallback
      z.t.expect.reply "value=tail"

      z.arg.named "key[0]" "key[0]=value" default=fallback
      z.t.expect.reply "value"
    }
  }
}

z.t.describe "z.arg.parse"; {
  z.t.context "名前付き引数と残りの引数が混在する場合"; {
    z.t.it "指定したローカル変数へ解析し、入力を保つ"; {
      local -a input_args=("first" "delimiter=," "other=two words" "" "--" "named=payload")
      local -A parsed_named=([delimiter]=" ")
      local -a parsed_args=("old")
      local REPLY="unchanged"

      z.arg.parse input=input_args named=parsed_named rest=parsed_args
      local result_code=$?
      local result_reply=$REPLY

      z.t.expect "$result_code" 0
      z.t.expect "$result_reply" ""
      z.t.expect "${parsed_named[delimiter]}" ","
      z.t.expect "${#parsed_args[@]}" 5
      z.t.expect "${parsed_args[1]}" "first"
      z.t.expect "${parsed_args[2]}" "other=two words"
      z.t.expect "${parsed_args[3]}" ""
      z.t.expect "${parsed_args[4]}" "--"
      z.t.expect "${parsed_args[5]}" "named=payload"
      z.t.expect "${#input_args[@]}" 6
      z.t.expect "${input_args[2]}" "delimiter=,"
    }
  }

  z.t.context "API引数の順序が異なる場合"; {
    z.t.it "名前で出力先を決定する"; {
      local -a input_args=("a" "key=value")
      local -A parsed_named=([key]="default")
      local -a parsed_args=()

      z.arg.parse rest=parsed_args input=input_args named=parsed_named

      z.t.expect "${parsed_named[key]}" "value"
      z.t.expect "${parsed_args[1]}" "a"
    }
  }

  z.t.context "入力が空の場合"; {
    z.t.it "各初期値を返し、残りの引数を空にする"; {
      local -a input_args=()
      local -A parsed_named=([delimiter]=" " [flag]=true [empty]=null)
      local -a parsed_args=("old")

      z.arg.parse input=input_args named=parsed_named rest=parsed_args

      z.t.expect "${parsed_named[delimiter]}" " "
      z.t.expect "${parsed_named[flag]}" 0
      z.t.expect "${parsed_named[empty]}" ""
      z.t.expect "${#parsed_args[@]}" 0
    }
  }

  z.t.context "同じ名前が複数回指定される場合"; {
    z.t.it "最初の値を採用し、同名の引数をすべて取り除く"; {
      local -a input_args=("key=first" "a" "key=second" "other=x")
      local -A parsed_named=([key]="default")
      local -a parsed_args=()

      z.arg.parse input=input_args named=parsed_named rest=parsed_args

      z.t.expect "${parsed_named[key]}" "first"
      z.t.expect "${#parsed_args[@]}" 2
      z.t.expect "${parsed_args[1]}" "a"
      z.t.expect "${parsed_args[2]}" "other=x"
    }

    z.t.it "最初の値が空なら初期値を採用する"; {
      local -a input_args=("key=" "key=second")
      local -A parsed_named=([key]="default")
      local -a parsed_args=()

      z.arg.parse input=input_args named=parsed_named rest=parsed_args

      z.t.expect "${parsed_named[key]}" "default"
      z.t.expect "${#parsed_args[@]}" 0
    }
  }

  z.t.context "値に真偽値、null、等号を含む場合"; {
    z.t.it "名前付きの値だけを既存の変換規約に従って扱う"; {
      local -a input_args=("yes=true" "no=false" "empty=null" "text=a=b" "true" "null" "")
      local -A parsed_named=([yes]="" [no]="" [empty]="fallback" [text]="")
      local -a parsed_args=()

      z.arg.parse input=input_args named=parsed_named rest=parsed_args

      z.t.expect "${parsed_named[yes]}" 0
      z.t.expect "${parsed_named[no]}" 1
      z.t.expect "${parsed_named[empty]}" "fallback"
      z.t.expect "${parsed_named[text]}" "a=b"
      z.t.expect "${#parsed_args[@]}" 3
      z.t.expect "${parsed_args[1]}" "true"
      z.t.expect "${parsed_args[2]}" "null"
      z.t.expect "${parsed_args[3]}" ""
    }
  }

  z.t.context "呼び出し元が一般的な変数名を使う場合"; {
    z.t.it "出力先と無関係なローカル変数を変更しない"; {
      local -a input=("name=value" "item")
      local -A named=([name]="default")
      local -a rest=()
      local arg="arg" key="key" value="value" args="args"

      z.arg.parse input=input named=named rest=rest
      local result_arg=$arg result_key=$key result_value=$value result_args=$args

      z.t.expect "${named[name]}" "value"
      z.t.expect "${rest[1]}" "item"
      z.t.expect "$result_arg" "arg"
      z.t.expect "$result_key" "key"
      z.t.expect "$result_value" "value"
      z.t.expect "$result_args" "args"
    }

    z.t.it "内側の解析結果と外側の解析結果を分離する"; {
      local -a outer_input=("key=outer" "outer-item")
      local -A outer_named=([key]="")
      local -a outer_rest=()
      z.arg.parse input=outer_input named=outer_named rest=outer_rest

      () {
        local -a outer_input=("key=inner" "inner-item")
        local -A outer_named=([key]="")
        local -a outer_rest=()
        z.arg.parse input=outer_input named=outer_named rest=outer_rest
        z.t.expect "${outer_named[key]}" "inner"
        z.t.expect "${outer_rest[1]}" "inner-item"
      }

      z.t.expect "${outer_named[key]}" "outer"
      z.t.expect "${outer_rest[1]}" "outer-item"
    }
  }

  z.t.context "API引数や変数の宣言が不足する場合"; {
    z.t.it "引数不足、未知の指定、未宣言を拒否して出力を保持する"; {
      local -a input_args=("key=value")
      local -A parsed_named=([key]="default")
      local -a parsed_args=("old")
      local REPLY="unchanged"

      z.arg.parse input=input_args named=parsed_named 2>/dev/null
      local missing_code=$?
      z.arg.parse input=input_args named=parsed_named unknown=parsed_args 2>/dev/null
      local unknown_code=$?
      z.arg.parse input=missing_array named=parsed_named rest=parsed_args 2>/dev/null
      local undeclared_code=$?

      z.t.expect "$missing_code" 1
      z.t.expect "$unknown_code" 1
      z.t.expect "$undeclared_code" 1
      z.t.expect "${parsed_named[key]}" "default"
      z.t.expect "${parsed_args[1]}" "old"
    }
  }

  z.t.context "受け付ける名前が空の場合"; {
    z.t.it "すべての入力要素をそのまま残す"; {
      local -a input_args=("true" "null" "" "input=data" 'x=$(print literal)')
      local -A parsed_named=()
      local -a parsed_args=()

      z.arg.parse input=input_args named=parsed_named rest=parsed_args

      z.t.expect "${#parsed_named[@]}" 0
      z.t.expect "${#parsed_args[@]}" 5
      z.t.expect "${parsed_args[1]}" "true"
      z.t.expect "${parsed_args[2]}" "null"
      z.t.expect "${parsed_args[3]}" ""
      z.t.expect "${parsed_args[4]}" "input=data"
      z.t.expect "${parsed_args[5]}" 'x=$(print literal)'
    }
  }

  z.t.context "宣言した名前自体が真偽値風の場合"; {
    z.t.it "キーを変換せずに名前付き引数を取得する"; {
      local -a input_args=("true=false" "item")
      local -A parsed_named=([true]="fallback")
      local -a parsed_args=()

      z.arg.parse input=input_args named=parsed_named rest=parsed_args

      z.t.expect "${parsed_named[true]}" 1
      z.t.expect "${parsed_args[1]}" "item"
    }
  }

  z.t.context "API引数が重複している場合"; {
    z.t.it "既存の引数取得と同じく最初の指定を使う"; {
      local -a input_args=("key=value" "item")
      local -A parsed_named=([key]="default")
      local -A ignored_named=([key]="unchanged")
      local -a parsed_args=()

      z.arg.parse input=input_args named=parsed_named named=ignored_named rest=parsed_args

      z.t.expect "${parsed_named[key]}" "value"
      z.t.expect "${ignored_named[key]}" "unchanged"
      z.t.expect "${parsed_args[1]}" "item"
    }
  }
}
