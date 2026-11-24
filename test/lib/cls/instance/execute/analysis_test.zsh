source ${z_main}

z.t.describe "z.cls.instance.execute._get"; {
  z.t.context "スカラーの結果を返す場合"; {
    z.t.it "配列のREPLYをスカラーの結果へ置き換える"; {
      () {
        local literal=false
        REPLY=(old values)

        z.cls.instance.execute._get literal
        local reply_type=${(t)REPLY}
        local value=$REPLY

        z.t.expect "$reply_type" scalar
        z.t.expect "$value" false
      }
    }
  }

  z.t.context "一般的なgetterの作業変数と同名の属性の場合"; {
    z.t.it "実体の配列を参照し要素の境界を保持する"; {
      () {
        local -a name=("" "two words" false null)

        z.cls.instance.execute._get name
        local -a result=("${REPLY[@]}")

        z.t.expect "${#result}" 4
        z.t.expect.is.null "$result[1]"
        z.t.expect "$result[2]" "two words"
        z.t.expect "$result[3]" false
        z.t.expect "$result[4]" null
      }
    }
  }

  z.t.context "動的スコープにあるスカラーの場合"; {
    z.t.it "falseを文字列として返す"; {
      () {
        local literal=false

        z.cls.instance.execute._get literal

        z.t.expect.reply false
      }
    }
  }

  z.t.context "空配列の場合"; {
    z.t.it "空配列の形を保つ"; {
      () {
        local -a items=()

        z.cls.instance.execute._get items

        local reply_type=${(t)REPLY}
        local reply_count=${#REPLY}

        z.t.expect "$reply_count" 0
        z.t.expect.includes "$reply_type" array
      }
    }
  }

  z.t.context "余分な引数がある場合"; {
    z.t.it "取得を拒否する"; {
      z.cls.instance.execute._get literal extra

      z.t.expect.status.is.false
    }
  }
}
