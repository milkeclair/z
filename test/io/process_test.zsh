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

      z.t.expect.null $output
    }
  }

  z.t.context "colorオプションが指定された場合"; {
    z.t.it "引数を指定された色で出力する"; {
      local output=$(z.io "hello" "world" color=red)

      z.t.expect $output $'\033[31mhello world\033[0m'
    }
  }

  z.t.context "indentオプションが指定された場合"; {
    z.t.it "引数を指定されたインデントレベルで出力する"; {
      local output=$(z.io "hello" "world" indent=2)

      z.t.expect $output "    hello world"
    }
  }

  z.t.context "colorオプションとindentオプションが両方指定された場合"; {
    z.t.it "引数を指定された色とインデントレベルで出力する"; {
      local output=$(z.io "hello" "world" color=blue indent=1)

      z.t.expect $output $'\033[34m  hello world\033[0m'
    }
  }

  z.t.context "colorオプションとindentオプションが指定され、引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io color=blue indent=1)

      z.t.expect.null $output
    }
  }
}

z.t.describe "z.io.empty"; {
  z.t.context "呼び出された場合"; {
    z.t.it "空行を出力する"; {
      local output=$(z.io.empty)

      z.t.expect.null $output
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

      z.t.expect.null $output
    }
  }

  z.t.context "colorオプションが指定された場合"; {
    z.t.it "引数を指定された色で出力する"; {
      local output=$(z.io.oneline "hello" "world" color=green)

      z.t.expect $output $'\033[32mhello world\033[0m'
    }
  }

  z.t.context "indentオプションが指定された場合"; {
    z.t.it "引数を指定されたインデントレベルで出力する"; {
      local output=$(z.io.oneline "hello" "world" indent=3)

      z.t.expect $output "      hello world"
    }
  }

  z.t.context "colorオプションとindentオプションが両方指定された場合"; {
    z.t.it "引数を指定された色とインデントレベルで出力する"; {
      local output=$(z.io.oneline "hello" "world" color=yellow indent=2)

      z.t.expect $output $'\033[33m    hello world\033[0m'
    }
  }

  z.t.context "オプションが渡され、複数回呼び出された場合"; {
    z.t.it "引数を指定された色とインデントレベルで連結して出力する"; {
      local output=""
      output+=$(z.io.oneline "hello" color=cyan indent=1)
      output+=$(z.io.oneline "world" color=yellow indent=1)

      z.t.expect $output $'\033[36m  hello\033[0m\033[33m  world\033[0m'
    }
  }

  z.t.context "colorオプションとindentオプションが指定され、引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.oneline color=yellow indent=2)

      z.t.expect.null $output
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

      z.t.expect.null $output
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "標準入力を/dev/nullにリダイレクトする"; {
      local output=$(z.io "This will be discarded" | z.io.null)

      z.t.expect.null $output
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

      z.t.expect.null $output
    }
  }

  z.t.context "colorオプションが指定された場合"; {
    z.t.it "引数を指定された色で出力する"; {
      local output=$(z.io.line "hello" "world" color=magenta)

      z.t.expect $output $'\033[35mhello\033[0m\n\033[35mworld\033[0m'
    }
  }

  z.t.context "indentオプションが指定された場合"; {
    z.t.it "引数を指定されたインデントレベルで出力する"; {
      local output=$(z.io.line "hello" "world" indent=2)

      z.t.expect $output $'    hello\n    world'
    }
  }

  z.t.context "colorオプションとindentオプションが両方指定された場合"; {
    z.t.it "引数を指定された色とインデントレベルで出力する"; {
      local output=$(z.io.line "hello" "world" color=blue indent=1)

      z.t.expect $output $'\033[34m  hello\033[0m\n\033[34m  world\033[0m'
    }
  }

  z.t.context "colorオプションとindentオプションが指定され、引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.line color=blue indent=1)

      z.t.expect.null $output
    }
  }
}

z.t.describe "z.io.read"; {
  z.t.context "標準入力から1行読み込んだ場合"; {
    z.t.it "その行をREPLYに格納する"; {
      local input="sample input line"
      local output=$(echo $input | z.io.read; echo $REPLY)

      z.t.expect $output $input
    }
  }

  z.t.context "空行を標準入力から読み込んだ場合"; {
    z.t.it "REPLYを空にする"; {
      local output=$(echo "" | z.io.read; echo -n $REPLY)

      z.t.expect.null $output
    }
  }
}

z.t.describe "z.io.success"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を緑色で標準出力に出力する"; {
      local output=$(z.io.success "Operation completed successfully")

      z.t.expect $output $'\033[32mOperation completed successfully\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.success)

      z.t.expect.null $output
    }
  }

  z.t.context "colorオプションが指定された場合"; {
    z.t.it "引数を指定された色で標準出力に出力する"; {
      local output=$(z.io.success "Custom success message" color=cyan)

      z.t.expect $output $'\033[36mCustom success message\033[0m'
    }
  }

  z.t.context "indentオプションが指定された場合"; {
    z.t.it "引数を指定されたインデントレベルで標準出力に出力する"; {
      local output=$(z.io.success "Indented success message" indent=2)

      z.t.expect $output $'\033[32m    Indented success message\033[0m'
    }
  }

  z.t.context "colorオプションとindentオプションが両方指定された場合"; {
    z.t.it "引数を指定された色とインデントレベルで標準出力に出力する"; {
      local output=$(z.io.success "Colored and indented success" color=magenta indent=3)

      z.t.expect $output $'\033[35m      Colored and indented success\033[0m'
    }
  }

  z.t.context "colorオプションとindentオプションが指定され、引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.success color=magenta indent=3)

      z.t.expect.null $output
    }
  }
}

z.t.describe "z.io.warn"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を黄色で標準出力に出力する"; {
      local output=$(z.io.warn "This is a warning message")

      z.t.expect $output $'\033[33mThis is a warning message\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.warn)

      z.t.expect.null $output
    }
  }

  z.t.context "colorオプションが指定された場合"; {
    z.t.it "引数を指定された色で標準出力に出力する"; {
      local output=$(z.io.warn "Custom warning message" color=cyan)

      z.t.expect $output $'\033[36mCustom warning message\033[0m'
    }
  }

  z.t.context "indentオプションが指定された場合"; {
    z.t.it "引数を指定されたインデントレベルで標準出力に出力する"; {
      local output=$(z.io.warn "Indented warning message" indent=2)

      z.t.expect $output $'\033[33m    Indented warning message\033[0m'
    }
  }

  z.t.context "colorオプションとindentオプションが両方指定された場合"; {
    z.t.it "引数を指定された色とインデントレベルで標準出力に出力する"; {
      local output=$(z.io.warn "Colored and indented warning" color=magenta indent=3)

      z.t.expect $output $'\033[35m      Colored and indented warning\033[0m'
    }
  }

  z.t.context "colorオプションとindentオプションが指定され、引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.warn color=magenta indent=3)

      z.t.expect.null $output
    }
  }
}

z.t.describe "z.io.error"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を赤色で標準エラー出力に出力する"; {
      local output=$(z.io.error "error message" 2>&1 1>/dev/null)

      z.t.expect $output $'\033[31merror message\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.error 2>&1 1>/dev/null)

      z.t.expect.null $output
    }
  }

  z.t.context "colorオプションが指定された場合"; {
    z.t.it "引数を指定された色で標準エラー出力に出力する"; {
      local output=$(z.io.error "Custom error message" color=cyan 2>&1 1>/dev/null)

      z.t.expect $output $'\033[36mCustom error message\033[0m'
    }
  }

  z.t.context "indentオプションが指定された場合"; {
    z.t.it "引数を指定されたインデントレベルで標準エラー出力に出力する"; {
      local output=$(z.io.error "Indented error message" indent=2 2>&1 1>/dev/null)

      z.t.expect $output $'\033[31m    Indented error message\033[0m'
    }
  }

  z.t.context "colorオプションとindentオプションが両方指定された場合"; {
    z.t.it "引数を指定された色とインデントレベルで標準エラー出力に出力する"; {
      local output=$(z.io.error "Colored and indented error" color=magenta indent=3 2>&1 1>/dev/null)

      z.t.expect $output $'\033[35m      Colored and indented error\033[0m'
    }
  }

  z.t.context "colorオプションとindentオプションが指定され、引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.error color=magenta indent=3 2>&1 1>/dev/null)

      z.t.expect.null $output
    }
  }
}
