source ${z_main}

z.t.describe "z.git.stats"; {
  z.t.context "呼び出した場合"; {
    z.t.it "z.git.stats.showを呼び出す"; {
      z.t.mock name="z.io.line"
      z.t.mock name="z.io"
      z.t.mock name="z.git.stats.show" behavior="z.return called"

      z.git.stats

      z.t.expect.reply "called"
    }
  }

  z.t.context "引数を渡した場合"; {
    z.t.it "z.git.stats.showに引数を渡す"; {
      z.t.mock name="z.io.line"
      z.t.mock name="z.io"
      z.t.mock name="z.git.stats.show"

      z.git.stats exclude_exts="md log" exclude_dirs="docs tests"

      z.t.mock.result
      z.t.expect.reply.is.arr "exclude_exts=md log" "exclude_dirs=docs tests"
    }
  }
}

z.t.describe "z.git.stats.show"; {
  z.t.context "呼び出した場合"; {
    z.t.it "z.git.stats.authorを呼び出す"; {
      z.t.mock name="z.git.stats.exclude.exts"
      z.t.mock name="z.git.stats.exclude.dirs"
      z.t.mock name="z.git.stats.exclude"
      z.t.mock name="z.git.stats.author" behavior="z.return called"

      z.git.stats.show

      z.t.expect.reply "called"
    }
  }

  z.t.context "exclude_extsとexclude_dirsを渡した場合"; {
    z.t.it "z.git.stats.excludeに引数を渡す"; {
      z.t.mock name="z.git.stats.exclude.exts" behavior='z.return "md log"'
      z.t.mock name="z.git.stats.exclude.dirs" behavior='z.return "docs tests"'
      z.t.mock name="z.git.stats.exclude"
      z.t.mock name="z.git.stats.author"

      z.git.stats.show exclude_exts="md log" exclude_dirs="docs tests"

      z.t.mock.result name="z.git.stats.exclude"
      z.t.expect.reply.is.arr "exclude_exts=md log" "exclude_dirs=docs tests"
    }

    z.t.it "z.git.stats.authorに引数を渡す"; {
      z.t.mock name="z.git.stats.exclude.exts" behavior='z.return "md log"'
      z.t.mock name="z.git.stats.exclude.dirs" behavior='z.return "docs tests"'
      z.t.mock name="z.git.stats.exclude"
      z.t.mock name="z.git.stats.author"

      z.git.stats.show exclude_exts="md log" exclude_dirs="docs tests"

      z.t.mock.result name="z.git.stats.author"
      z.t.expect.reply.is.arr "exclude_exts=md log" "exclude_dirs=docs tests"
    }
  }
}

z.t.describe "z.git.stats.exclude"; {
  z.t.context "exclude_extsとexclude_dirsを渡した場合"; {
    z.t.it "exclude_extsとexclude_dirsを表示する"; {
      z.t.mock name="z.io.line"

      z.git.stats.exclude exclude_exts="md log" exclude_dirs="docs tests"

      z.t.mock.result name="z.io.line"
      z.t.expect.reply.is.arr "exclude_exts: md log" "exclude_dirs: docs tests"
    }
  }
}

z.t.describe "z.git.stats.author"; {
  z.t.context "呼び出した場合"; {
    z.t.it "header, body, footerの順で呼び出す"; {
      z.t.mock name="z.git.stats.author.header" behavior="z.io header"
      z.t.mock name="z.git.stats.author.body" behavior="z.io body"
      z.t.mock name="z.git.stats.author.footer" behavior="z.io footer"

      local result=$(z.git.stats.author)

      z.t.expect "$result" $'header\nbody\nfooter'
    }
  }
}
