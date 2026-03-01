source ${z_main}

z.t.describe "z.git.stats.exclude.exts"; {
  z.t.context "exclude_extsを渡した場合"; {
    z.t.it "そのまま返す"; {
      z.git.stats.exclude.exts exclude_exts="html css js"

      z.t.expect.reply "html css js"
    }
  }

  z.t.context "exclude_extsを渡さなかった場合"; {
    z.t.it "デフォルトの拡張子を返す"; {
      z.git.stats.exclude.exts

      z.t.expect.reply "log lock"
    }
  }
}

z.t.describe "z.git.stats.exclude.dirs"; {
  z.t.context "exclude_dirsを渡した場合"; {
    z.t.it "そのまま返す"; {
      z.git.stats.exclude.dirs exclude_dirs="src app"

      z.t.expect.reply "src app"
    }
  }

  z.t.context "exclude_dirsを渡さなかった場合"; {
    z.t.it "デフォルトのディレクトリを返す"; {
      z.git.stats.exclude.dirs

      z.t.expect.reply "node_modules dist"
    }
  }
}
