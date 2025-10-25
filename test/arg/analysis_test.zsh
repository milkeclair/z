source ${z_main}

z.t.describe "z.arg.get"; {
  z.t.context "存在するインデックスを指定した場合"; {
    z.t.it "指定したインデックスの引数を返す"; {
      z.arg.get index=2 "a" "b" "c"

      z.t.expect.reply "b"
    }
  }

  z.t.context "インデックスが正の整数の場合"; {
    z.t.it "指定したインデックスの引数を判定して返す"; {
      z.arg.get index=1 "a" "b" "c"

      z.t.expect.reply "a"
    }
  }

  z.t.context "インデックスが負の整数の場合"; {
    z.t.it "指定したインデックスの引数を末尾から判定して返す"; {
      z.arg.get index=-1 "a" "b" "c"

      z.t.expect.reply "c"
    }
  }

  z.t.context "存在しないインデックスを指定した場合"; {
    z.t.it "nullを返す"; {
      z.arg.get index=4 "a" "b" "c"

      z.t.expect.reply.null
    }
  }

  z.t.context "インデックスがnullの場合"; {
    z.t.it "nullを返す"; {
      z.arg.get "a" "b" "c"

      z.t.expect.reply.null
    }
  }

  z.t.context "インデックスが整数でない場合"; {
    z.t.it "nullを返す"; {
      z.arg.get index=not-integer "a" "b" "c"

      z.t.expect.reply.null
    }
  }

  z.t.context "インデックスが0の場合"; {
    z.t.it "nullを返す"; {
      z.arg.get index=0 "a" "b" "c"

      z.t.expect.reply.null
    }
  }

  z.t.context "引数を指定しなかった場合"; {
    z.t.it "nullを返す"; {
      z.arg.get index=1

      z.t.expect.reply.null
    }
  }
}

z.t.describe "z.arg.first"; {
  z.t.context "引数が存在する場合"; {
    z.t.it "最初の引数を返す"; {
      z.arg.first "a" "b" "c"

      z.t.expect.reply "a"
    }
  }

  z.t.context "引数が存在しない場合"; {
    z.t.it "nullを返す"; {
      z.arg.first

      z.t.expect.reply.null
    }
  }
}

z.t.describe "z.arg.second"; {
  z.t.context "引数が2つ以上存在する場合"; {
    z.t.it "2番目の引数を返す"; {
      z.arg.second "a" "b" "c"

      z.t.expect.reply "b"
    }
  }

  z.t.context "引数が1つしか存在しない場合"; {
    z.t.it "nullを返す"; {
      z.arg.second "a"

      z.t.expect.reply.null
    }
  }

  z.t.context "引数が存在しない場合"; {
    z.t.it "nullを返す"; {
      z.arg.second

      z.t.expect.reply.null
    }
  }
}

z.t.describe "z.arg.third"; {
  z.t.context "引数が3つ以上存在する場合"; {
    z.t.it "3番目の引数を返す"; {
      z.arg.third "a" "b" "c" "d"

      z.t.expect.reply "c"
    }
  }

  z.t.context "引数が2つしか存在しない場合"; {
    z.t.it "nullを返す"; {
      z.arg.third "a" "b"

      z.t.expect.reply.null
    }
  }

  z.t.context "引数が存在しない場合"; {
    z.t.it "nullを返す"; {
      z.arg.third

      z.t.expect.reply.null
    }
  }
}

z.t.describe "z.arg.last"; {
  z.t.context "引数が存在する場合"; {
    z.t.it "最後の引数を返す"; {
      z.arg.last "a" "b" "c"

      z.t.expect.reply "c"
    }
  }

  z.t.context "引数が存在しない場合"; {
    z.t.it "nullを返す"; {
      z.arg.last

      z.t.expect.reply.null
    }
  }
}
