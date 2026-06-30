source ${z_main}

z.t.describe "z.completion.function.name._declaration"; {
  z.t.context "z関数宣言行を指定した場合"; {
    z.t.it "関数名を返す"; {
      z.completion.function.name._declaration "z.example.test() {"

      z.t.expect.reply "z.example.test"
    }
  }

  z.t.context "先頭に空白があるz関数宣言行を指定した場合"; {
    z.t.it "関数名を返す"; {
      z.completion.function.name._declaration "  z.example.test() {"

      z.t.expect.reply "z.example.test"
    }
  }

  z.t.context "z関数ではない宣言行を指定した場合"; {
    z.t.it "falseを返す"; {
      z.completion.function.name._declaration "example.test() {"

      z.t.expect.status.is.false
    }
  }

  z.t.context "宣言suffixがbraceではない場合"; {
    z.t.it "falseを返す"; {
      z.completion.function.name._declaration "z.example.test() echo"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.completion.function.name._words"; {
  z.t.context "wordsにz関数がある場合"; {
    z.t.it "現在位置に近い関数名を返す"; {
      words=(z.arg.named "")
      CURRENT=2

      z.completion.function.name._words

      z.t.expect.reply "z.arg.named"
    }
  }

  z.t.context "CURRENTがwordsの範囲を超えている場合"; {
    z.t.it "最後のwordから探す"; {
      words=(z.arg.named "")
      CURRENT=9

      z.completion.function.name._words

      z.t.expect.reply "z.arg.named"
    }
  }

  z.t.context "現在位置に未定義のz関数名がある場合"; {
    z.t.it "手前の定義済みz関数名を返す"; {
      words=(z.arg.named z.not.exists) # zls: ignore
      CURRENT=2

      z.completion.function.name._words

      z.t.expect.reply "z.arg.named"
    }
  }

  z.t.context "wordsに定義済みz関数がない場合"; {
    z.t.it "falseを返す"; {
      words=(example z.not.exists "") # zls: ignore
      CURRENT=3

      z.completion.function.name._words

      z.t.expect.status.is.false
    }
  }
}
