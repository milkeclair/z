source ${z_main}

z.t.describe "z.git.stats.commit.map"; {
  z.t.context "authorsを渡した場合"; {
    z.t.it "authorごとのcommit_count, inserted, deletedを含むエントリーの配列を返す"; {
      z.t.mock name="z.git.stats.commit.details" behavior='
        if z.is.eq "$author" "Alice"; then
          z.return "1000 500"
        elif z.is.eq "$author" "Bob"; then
          z.return "800 300"
        else
          z.io "Unexpected author: $author"
          return 1
        fi
      '
      z.t.mock name="z.git.stats.commit.count" behavior='
        if z.is.eq "$author" "Alice"; then
          z.return 50
        elif z.is.eq "$author" "Bob"; then
          z.return 40
        else
          z.io "Unexpected author: $author"
          return 1
        fi
      '

      z.git.stats.commit.map authors="Alice Bob"

      z.t.expect.reply.is.arr "Alice:1000 500:50" "Bob:800 300:40"
    }
  }

  z.t.context "authorのコミット数が0の場合"; {
    z.t.it "そのauthorのエントリーは返さない"; {
      z.t.mock name="z.git.stats.commit.details" behavior='
        if z.is.eq "$author" "Alice"; then
          z.return "1000 500"
        elif z.is.eq "$author" "Bob"; then
          z.return "800 300"
        else
          z.io "Unexpected author: $author"
          return 1
        fi
      '
      z.t.mock name="z.git.stats.commit.count" behavior='
        if z.is.eq "$author" "Alice"; then
          z.return 50
        elif z.is.eq "$author" "Bob"; then
          z.return 0
        else
          z.io "Unexpected author: $author"
          return 1
        fi
      '

      z.git.stats.commit.map authors="Alice Bob"

      z.t.expect.reply.is.arr "Alice:1000 500:50"
    }
  }

  z.t.context "authorsが空の場合"; {
    z.t.it "空の配列を返す"; {
      z.git.stats.commit.map authors=""

      z.t.expect.reply.is.arr
    }
  }

  z.t.context "exclude_extsとexclude_dirsを渡した場合"; {
    z.t.it "z.git.stats.commit.detailsにexclude_extsとexclude_dirsを渡す"; {
      z.t.mock name="z.git.stats.commit.details"
      z.t.mock name="z.git.stats.commit.count" behavior="z.return 1"

      z.git.stats.commit.map authors="Alice" exclude_exts="md txt" exclude_dirs="docs tests"

      z.t.mock.result name="z.git.stats.commit.details"
      z.t.expect.reply "author=Alice exclude_exts=md txt exclude_dirs=docs tests"
    }
  }
}

z.t.describe "z.git.stats.commit.details"; {
  z.t.context "authorを渡した場合"; {
    z.t.it "そのauthorのinsertedとdeletedを返す"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "log --pretty=tformat: --numstat --author=milkeclair"; then
          echo "1000 500"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.stats.commit.details author="milkeclair"

      z.t.expect.reply "1000 500"
    }
  }

  z.t.context "authorが存在しない場合"; {
    z.t.it "0 0を返す"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "log --pretty=tformat: --numstat --author=unknown"; then
          echo "0 0"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.stats.commit.details author="unknown"

      z.t.expect.reply "0 0"
    }
  }

  z.t.context "exclude_extsとexclude_dirsを渡した場合"; {
    z.t.it "指定された拡張子とディレクトリを除外する"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "log --pretty=tformat: --numstat --author=milkeclair"; then
          z.io "800 300 file.txt" # excluded by ext
          z.io "600 200 file.zsh" # included
          z.io "400 100 docs/file.ts" # excluded by dir
          z.io "400 100 test/file_test.zsh" # excluded by dir
          z.io "200 50 dir/file_test.zsh" # included
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.stats.commit.details \
        author="milkeclair" \
        exclude_exts="md txt" \
        exclude_dirs="docs test"

      z.t.expect.reply "800 250"
    }
  }
}

z.t.describe "z.git.stats.commit.sum_lines"; {
  z.t.context "insertedとdeletedを渡した場合"; {
    z.t.it "insertedとdeletedの合計を返す"; {
      z.git.stats.commit.sum_lines inserted=1000 deleted=500

      z.t.expect.reply 1500
    }
  }
}
