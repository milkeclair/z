source ${z_main}

z.t.describe "z.path.dir"; {
  z.t.context "有効なパス文字列が渡された場合"; {
    z.t.it "そのパスのディレクトリ部分を返す"; {
      z.path.dir "/usr/local/bin/somefile.txt"
      z.t.expect.reply "/usr/local/bin"

      z.path.dir "/home/user/docs/"
      z.t.expect.reply "/home/user"
    }
  }

  z.t.context "無効なパス文字列が渡された場合"; {
    z.t.it "空文字列を返す"; {
      z.path.dir ""
      z.t.expect.reply.is.null

      z.path.dir ":::"
      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.path.base"; {
  z.t.context "有効なパス文字列が渡された場合"; {
    z.t.it "そのパスのベース名部分を返す"; {
      z.path.base "/usr/local/bin/somefile.txt"
      z.t.expect.reply "somefile.txt"

      z.path.base "/home/user/docs/"
      z.t.expect.reply "docs"
    }
  }

  z.t.context "無効なパス文字列が渡された場合"; {
    z.t.it "空文字列を返す"; {
      z.path.base ""
      z.t.expect.reply.is.null

      z.path.base ":::"
      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.path.stem"; {
  z.t.context "有効なパス文字列が渡された場合"; {
    z.t.it "そのパスの拡張子を除いたベース名部分を返す"; {
      z.path.stem "/usr/local/bin/somefile.txt"
      z.t.expect.reply "somefile"

      z.path.stem "/home/user/docs/report.pdf"
      z.t.expect.reply "report"
    }
  }

  z.t.context "無効なパス文字列が渡された場合"; {
    z.t.it "空文字列を返す"; {
      z.path.stem ""
      z.t.expect.reply.is.null

      z.path.stem ":::"
      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.path.ext"; {
  z.t.context "有効なパス文字列が渡された場合"; {
    z.t.it "そのパスの拡張子部分を返す"; {
      z.path.ext "/usr/local/bin/somefile.txt"
      z.t.expect.reply "txt"

      z.path.ext "/home/user/docs/report.pdf"
      z.t.expect.reply "pdf"
    }
  }

  z.t.context "無効なパス文字列が渡された場合"; {
    z.t.it "空文字列を返す"; {
      z.path.ext ""
      z.t.expect.reply.is.null

      z.path.ext ":::"
      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.path.real"; {
  z.t.context "有効なパス文字列が渡された場合"; {
    z.t.it "そのパスの実際のパスを返す"; {
      z.path.real "."
      z.t.expect.reply $(pwd)

      z.path.real ".."
      z.t.expect.reply $(dirname $(pwd))
    }

    z.t.it "シンボリックリンクを解決して実体のパスを返す"; {
      local tmpdir=$(mktemp -d)
      local actual_file="$tmpdir/actual.txt"
      local symlink="$tmpdir/link.txt"

      touch $actual_file
      ln -s $actual_file $symlink

      z.path.real $symlink
      z.t.expect.reply $actual_file

      rm -rf $tmpdir
    }
  }

  z.t.context "無効なパス文字列が渡された場合"; {
    z.t.it "空文字列を返す"; {
      z.path.real ""
      z.t.expect.reply.is.null

      z.path.real ":::"
      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.path.abs"; {
  z.t.context "有効なパス文字列が渡された場合"; {
    z.t.it "そのパスの絶対パスを返す"; {
      z.path.abs "."
      z.t.expect.reply $(pwd)

      z.path.abs ".."
      z.t.expect.reply $(dirname $(pwd))
    }

    z.t.it "シンボリックリンクを解決せずそのまま絶対パスを返す"; {
      local tmpdir=$(mktemp -d)
      local actual_file="$tmpdir/actual.txt"
      local symlink="$tmpdir/link.txt"

      touch $actual_file
      ln -s $actual_file $symlink

      z.path.abs $symlink
      z.t.expect.reply $symlink

      rm -rf $tmpdir
    }
  }

  z.t.context "無効なパス文字列が渡された場合"; {
    z.t.it "空文字列を返す"; {
      z.path.abs ""
      z.t.expect.reply.is.null

      z.path.abs ":::"
      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.path.downcase"; {
  z.t.it "パス文字列を小文字に変換して返す"; {
    z.path.downcase "/UsR/LoCaL/Bin/SomeFile.TXT"
    z.t.expect.reply "/usr/local/bin/somefile.txt"

    z.path.downcase "/HoMe/UsEr/DoCs/Report.PDF"
    z.t.expect.reply "/home/user/docs/report.pdf"
  }
}

z.t.describe "z.path.upcase"; {
  z.t.it "パス文字列を大文字に変換して返す"; {
    z.path.upcase "/UsR/LoCaL/Bin/SomeFile.TXT"
    z.t.expect.reply "/USR/LOCAL/BIN/SOMEFILE.TXT"

    z.path.upcase "/HoMe/UsEr/DoCs/Report.PDF"
    z.t.expect.reply "/HOME/USER/DOCS/REPORT.PDF"
  }
}
