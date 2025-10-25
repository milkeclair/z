source ${z_main}

z.t.describe "z.io"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数をスペース区切りで出力する"; {
      local output=$(z.io "hello" "world")

      z.t.expect $output "hello world"
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "空行を出力する"; {
      local output=$(z.io)

      z.t.expect $output ""
    }
  }
}

z.t.describe "z.io.empty"; {
  z.t.context "呼び出された場合"; {
    z.t.it "空行を出力する"; {
      local output=$(z.io.empty)

      z.t.expect $output ""
    }
  }
}

z.t.describe "z.io.oneline"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を改行なしで出力する"; {
      local output=$(z.io.oneline "hello" "world")

      z.t.expect $output "hello world"
    }
  }

  z.t.context "複数回呼び出された場合"; {
    z.t.it "引数を改行なしで連結して出力する"; {
      local output=""
      output+=$(z.io.oneline "hello")
      output+=$(z.io.oneline "world")

      z.t.expect $output "helloworld"
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.oneline)

      z.t.expect $output ""
    }
  }
}

z.t.describe "z.io.clear"; {
  z.t.context "呼び出された場合"; {
    z.t.it "端末の画面をクリアする制御文字を出力する"; {
      local output=$(z.io.clear)

      z.t.expect $output $'\033c'
    }
  }
}

z.t.describe "z.io.null"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "コマンドを実行し、標準出力と標準エラー出力を/dev/nullにリダイレクトする"; {
      local output=$(z.io.null ls -la 2>&1)

      z.t.expect $output ""
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "標準入力を/dev/nullにリダイレクトする"; {
      local output=$(z.io "This will be discarded" | z.io.null)

      z.t.expect $output ""
    }
  }
}

z.t.describe "z.io.line"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を改行区切りで出力する"; {
      local output=$(z.io.line "hello" "world")

      z.t.expect $output $'hello\nworld'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.line)

      z.t.expect $output ""
    }
  }
}

z.t.describe "z.io.indent"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "指定されたインデントレベルで引数をインデントして出力する"; {
      local output=$(z.io.indent level=4 "hello" "world")

      z.t.expect $output "        hello world"
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "インデントのみを出力する"; {
      local output=$(z.io.indent level=4 "hello")

      z.t.expect $output "        hello"
    }
  }
}

z.t.describe "z.io.error"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を標準エラー出力に出力する"; {
      local output=$(z.io.error "error message" 2>&1 1>/dev/null)

      z.t.expect $output "error message"
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.error 2>&1 1>/dev/null)

      z.t.expect $output ""
    }
  }
}

z.t.describe "z.io.error.line"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を改行区切りで標準エラー出力に出力する"; {
      local output=$(z.io.error.line "error" "message" 2>&1 1>/dev/null)

      z.t.expect $output $'error\nmessage'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.error.line 2>&1 1>/dev/null)

      z.t.expect $output ""
    }
  }
}

z.t.describe "z.io.error.indent"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "指定されたインデントレベルで引数をインデントして標準エラー出力に出力する"; {
      local output=$(z.io.error.indent level=3 "error message" 2>&1 1>/dev/null)

      z.t.expect $output "      error message"
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "インデントのみを標準エラー出力に出力する"; {
      local output=$(z.io.error.indent level=3 "error" 2>&1 1>/dev/null)

      z.t.expect $output "      error"
    }
  }
}
