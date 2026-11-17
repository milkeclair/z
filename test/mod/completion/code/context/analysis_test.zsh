source "$z_main"

z.t.describe "z.completion.code.context._prefix"; {
  z.t.it "末尾にカーソルがあれば値全体を返す"; {
    z.completion.code.context._prefix value="print ok" prefix=code= input_prefix=ignored input_suffix=""

    z.t.expect.reply "print ok"
  }

  z.t.it "途中では名前付き接頭辞とsuffixを除いた部分を返す"; {
    z.completion.code.context._prefix value=greet prefix=code= input_prefix=code=gr input_suffix=eet

    z.t.expect.reply gr
  }

  z.t.it "ZLEがescapeしたprefixを復号する"; {
    z.completion.code.context._prefix value="print ok" prefix=code= 'input_prefix=code=print\ ' input_suffix=ok

    z.t.expect.reply "print "
  }
}

z.t.describe "z.completion.code.context._words"; {
  z.t.it "区切りの前のコマンドを除き、現在の単語を返す"; {
    z.completion.code.context._words "print ok; greet value"
    z.t.expect.reply.is.arr greet value

    z.completion.code.context._words "print ok | greet"
    z.t.expect.reply.is.arr greet
  }

  z.t.it "空白なしの区切り直後でも空の補完単語を返す"; {
    z.completion.code.context._words "true;"
    z.t.expect.reply.is.arr ""

    z.completion.code.context._words "true; "
    z.t.expect.reply.is.arr ""
  }

  z.t.it "先頭の制御語と通常の引数の制御語を区別する"; {
    z.completion.code.context._words "if true; then greet value"
    z.t.expect.reply.is.arr greet value

    z.completion.code.context._words "print then"
    z.t.expect.reply.is.arr print then
  }

  z.t.it "引用した区切りを単語として保持する"; {
    z.completion.code.context._words "print ';'"

    z.t.expect.reply.is.arr print "';'"
  }

  z.t.it "コメント内では補完の文脈を返さない"; {
    z.completion.code.context._words "print ok # greet"

    z.t.expect.status.is.false
  }
}

z.t.describe "z.completion.code.context._substitution_cursor"; {
  z.t.it "コードの接頭辞から引用内のカーソル前後を復元する"; {
    z.completion.code.context._substitution_cursor 'word="$(greet)"' 'prefix="$(gr'

    z.t.expect.reply.is.arr '$(gr' 'eet)'
  }

  z.t.it "引用されていない単語と閉じていない単語を対象にしない"; {
    z.completion.code.context._substitution_cursor word=greet prefix=gr
    z.t.expect.status.is.false

    z.completion.code.context._substitution_cursor 'word="$(gr' 'prefix="$(gr'
    z.t.expect.status.is.false
  }
}
