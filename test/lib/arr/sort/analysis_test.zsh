source ${z_main}

z.t.describe "z.arr.sort.numeric"; {
  z.t.context "正負の整数がある場合"; {
    z.t.it "既定で数値の昇順に並べる"; {
      z.arr.sort.numeric 10 -2 0 -10 2
      z.t.expect.reply.is.arr "-10" "-2" "0" "2" "10"
    }
  }

  z.t.context "降順を指定した場合"; {
    z.t.it "数値の降順に並べる"; {
      z.arr.sort.numeric by=desc 10 -2 0 -10 2
      z.t.expect.reply.is.arr "10" "2" "0" "-2" "-10"
    }
  }

  z.t.context "符号や先頭ゼロがある場合"; {
    z.t.it "元の表記を保持して同値は入力順に返す"; {
      z.arr.sort.numeric +2 002 2 -000 0 +00 -02 -2
      z.t.expect.reply.is.arr "-02" "-2" "-000" "0" "+00" "+2" "002" "2"
    }
  }

  z.t.context "整数の桁数が機械整数を超える場合"; {
    z.t.it "桁あふれせず並べる"; {
      z.arr.sort.numeric 100000000000000000000000000000 -99999999999999999999999999999 99999999999999999999999999999 -100000000000000000000000000000
      z.t.expect.reply.is.arr "-100000000000000000000000000000" "-99999999999999999999999999999" "99999999999999999999999999999" "100000000000000000000000000000"
    }
  }

  z.t.context "要素がない場合"; {
    z.t.it "空配列を返す"; {
      z.arr.sort.numeric
      z.t.expect.reply.is.arr
    }
  }

  z.t.context "nounsetが有効で入力要素がない場合"; {
    z.t.it "未定義の位置引数へアクセスせず空配列を返す"; {
      local result=$(
        setopt nounset
        z.arr.sort.numeric
        print -r -- "${#REPLY[@]}"
      )

      z.t.expect "$result" 0
    }
  }

  z.t.context "要素や並び順が不正な場合"; {
    z.t.it "失敗する"; {
      z.arr.sort.numeric 1 ""
      z.t.expect.status.is.false

      z.arr.sort.numeric 1 "1+2"
      z.t.expect.status.is.false

      z.arr.sort.numeric by=unknown 1
      z.t.expect.status.is.false
    }
  }
}
