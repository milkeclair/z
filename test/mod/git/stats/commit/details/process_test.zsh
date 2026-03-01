source ${z_main}

z.t.describe "z.git.stats.commit.details.excludes"; {
  z.t.context "exclude_extsとexclude_dirsを渡した場合"; {
    z.t.it "正規表現パターンを返す"; {
      z.git.stats.commit.details.excludes \
        exclude_exts="md txt" \
        exclude_dirs="docs test"

      z.t.expect.reply.is.arr "\\.(md|txt)$" "(docs|test)/"
    }
  }

  z.t.context "exclude_extsとexclude_dirsを渡さない場合"; {
    z.t.it "空のパターンを返す"; {
      z.git.stats.commit.details.excludes

      z.t.expect.reply.is.arr "\\.()$" "()/"
    }
  }
}
