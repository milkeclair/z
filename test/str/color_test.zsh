source ${z_main}

z.t.describe "z.str.color"; {
  z.t.context "z_color_paletteに定義されている色を指定した場合"; {
    z.t.it "指定した色のANSIエスケープ文字を返す"; {
      z.str.color "red"
      z.t.expect.reply $'\033[31m'

      z.str.color "green"
      z.t.expect.reply $'\033[32m'

      z.str.color "yellow"
      z.t.expect.reply $'\033[33m'

      z.str.color "blue"
      z.t.expect.reply $'\033[34m'

      z.str.color "magenta"
      z.t.expect.reply $'\033[35m'

      z.str.color "cyan"
      z.t.expect.reply $'\033[36m'

      z.str.color "white"
      z.t.expect.reply $'\033[37m'

      z.str.color "reset"
      z.t.expect.reply $'\033[0m'
    }
  }

  z.t.context "z_color_paletteに定義されていない色を指定した場合"; {
    z.t.it "空文字列を返す"; {
      z.str.color "unknown_color"
      z.t.expect.reply.null
    }
  }
}

z.t.describe "z.str.color.strip"; {
  z.t.context "色付きの文字列が渡された場合"; {
    z.t.it "色コードを除去した文字列を返す"; {
      z.str.color.strip $'\033[31mHello\033[0m'
      z.t.expect.reply "Hello"

      z.str.color.strip $'\033[32mWorld\033[0m'
      z.t.expect.reply "World"

      z.str.color.strip $'\033[33mYellow Text\033[0m'
      z.t.expect.reply "Yellow Text"
    }
  }

  z.t.context "色コードが含まれていない文字列が渡された場合"; {
    z.t.it "そのままの文字列を返す"; {
      z.str.color.strip "Plain Text"
      z.t.expect.reply "Plain Text"

      z.str.color.strip ""
      z.t.expect.reply.null
    }
  }
}

z.t.describe "z.str.color.decorate"; {
  z.t.context "色と文字列が渡された場合"; {
    z.t.it "指定した色で装飾された文字列を返す"; {
      z.str.color.decorate color=red message="Hello"
      z.t.expect.reply $'\033[31mHello\033[0m'

      z.str.color.decorate color=green message="World"
      z.t.expect.reply $'\033[32mWorld\033[0m'

      z.str.color.decorate color=blue message="Blue Text"
      z.t.expect.reply $'\033[34mBlue Text\033[0m'
    }
  }

  z.t.context "不明な色と文字列が渡された場合"; {
    z.t.it "装飾されていない文字列を返す"; {
      z.str.color.decorate color=unknown_color message="Hello"
      z.t.expect.reply "Hello"

      z.str.color.decorate color="" message="World"
      z.t.expect.reply "World"
    }
  }
}

z.t.describe "z.str.color.red"; {
  z.t.context "文字列が渡された場合"; {
    z.t.it "赤色で装飾された文字列を返す"; {
      z.str.color.red "Error"
      z.t.expect.reply $'\033[31mError\033[0m'
    }
  }
}

z.t.describe "z.str.color.green"; {
  z.t.context "文字列が渡された場合"; {
    z.t.it "緑色で装飾された文字列を返す"; {
      z.str.color.green "Success"
      z.t.expect.reply $'\033[32mSuccess\033[0m'
    }
  }
}

z.t.describe "z.str.color.yellow"; {
  z.t.context "文字列が渡された場合"; {
    z.t.it "黄色で装飾された文字列を返す"; {
      z.str.color.yellow "Warning"
      z.t.expect.reply $'\033[33mWarning\033[0m'
    }
  }
}

z.t.describe "z.str.color.blue"; {
  z.t.context "文字列が渡された場合"; {
    z.t.it "青色で装飾された文字列を返す"; {
      z.str.color.blue "Info"
      z.t.expect.reply $'\033[34mInfo\033[0m'
    }
  }
}

z.t.describe "z.str.color.magenta"; {
  z.t.context "文字列が渡された場合"; {
    z.t.it "マゼンタで装飾された文字列を返す"; {
      z.str.color.magenta "Notice"
      z.t.expect.reply $'\033[35mNotice\033[0m'
    }
  }
}

z.t.describe "z.str.color.cyan"; {
  z.t.context "文字列が渡された場合"; {
    z.t.it "シアンで装飾された文字列を返す"; {
      z.str.color.cyan "Cyan Text"
      z.t.expect.reply $'\033[36mCyan Text\033[0m'
    }
  }
}

z.t.describe "z.str.color.white"; {
  z.t.context "文字列が渡された場合"; {
    z.t.it "白色で装飾された文字列を返す"; {
      z.str.color.white "White Text"
      z.t.expect.reply $'\033[37mWhite Text\033[0m'
    }
  }
}
