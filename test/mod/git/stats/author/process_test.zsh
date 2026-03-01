source ${z_main}

z.t.describe "z.git.stats.author.header"; {
  z.t.context "呼び出した場合"; {
    z.t.it "作者統計のテーブルヘッダーを表示する"; {
      z.t.mock name="z.io"

      z.git.stats.author.header

      z.t.mock.result
      z.t.expect.reply.includes "│ author               │ commit     │ add        │ delete     │ total      │"
    }
  }
}

z.t.describe "z.git.stats.author.body"; {
  z.t.context "呼び出した場合"; {
    z.t.it "authorsの統計のテーブルボディを表示する"; {
      z.t.mock name="z.git.stats.author.names" behavior='z.return Alice Bob Charlie'
      z.t.mock \
        name="z.git.stats.commit.map" \
        behavior='z.return "Alice:1000 500:2" "Bob:800 300:1" "Charlie:600 200:1" keep_empty=true'
      z.t.mock name="z.str.color" behavior='z.return ""'
      z.t.mock name="z.git.stats.author.border"
      z.t.mock name="printf"

      z.git.stats.author.body exclude_exts="md" exclude_dirs="docs"

      local format="│ %-20s │ %-10d │ %-10d │ %-10d │ %-10d │\n"
      z.t.mock.result name="printf"
      z.t.expect.reply.is.arr \
        "$format" "Alice" "2" "1000" "500" "1500" \
        "$format" "Bob" "1" "800" "300" "1100" \
        "$format" "Charlie" "1" "600" "200" "800"
    }
  }

  z.t.context "最後のエントリーでない場合"; {
    z.t.it "エントリーの後にボーダーを表示する"; {
      z.t.mock name="z.git.stats.author.names" behavior='z.return Alice Bob'
      z.t.mock \
        name="z.git.stats.commit.map" \
        behavior='z.return "Alice:1000 500:2" "Bob:800 300:1" keep_empty=true'
      z.t.mock name="z.git.stats.author.show"
      z.t.mock name="z.git.stats.author.border" behavior='result="called"'

      z.git.stats.author.body

      z.t.expect $result "called"
      unset result
    }
  }

  z.t.context "最後のエントリーの場合"; {
    z.t.it "エントリーの後にボーダーを表示しない"; {
      z.t.mock name="z.git.stats.author.names" behavior='z.return Alice'
      z.t.mock \
        name="z.git.stats.commit.map" \
        behavior='z.return "Alice:1000 500:2" keep_empty=true'
      z.t.mock name="z.git.stats.author.show"
      z.t.mock name="z.git.stats.author.border" behavior='result="called"'

      z.git.stats.author.body

      z.t.expect $result ""
      unset result
    }
  }
}

z.t.describe "z.git.stats.author.show"; {
  z.t.context "呼び出した場合"; {
    z.t.it "作者の統計をテーブルの行として表示する"; {
      z.t.mock name="z.str.color" behavior='z.return ""'
      z.t.mock name="printf"

      z.git.stats.author.show \
        author="milkeclair" \
        commit_count=100 \
        inserted=1000 \
        deleted=1000 \
        total=2000

      local format="│ %-20s │ %-10d │ %-10d │ %-10d │ %-10d │\n"
      z.t.mock.result name="printf"
      z.t.expect.reply.is.arr \
        "$format" "milkeclair" "100" "1000" "1000" "2000"
    }
  }

  z.t.context "authorがnullの場合"; {
    z.t.it "authorをEveryoneとして表示する"; {
      z.t.mock name="z.str.color" behavior='z.return ""'
      z.t.mock name="printf"

      z.git.stats.author.show \
        author="" \
        commit_count=50 \
        inserted=500 \
        deleted=300 \
        total=800

      local format="│ %-20s │ %-10d │ %-10d │ %-10d │ %-10d │\n"
      z.t.mock.result name="printf"
      z.t.expect.reply.is.arr \
        "$format" "Everyone" "50" "500" "300" "800"
    }
  }
}

z.t.describe "z.git.stats.author.border"; {
  z.t.context "呼び出した場合"; {
    z.t.it "テーブルのボーダーを表示する"; {
      z.t.mock name="z.io"

      z.git.stats.author.border

      z.t.mock.result
      z.t.expect.reply "├──────────────────────┼────────────┼────────────┼────────────┼────────────┤"
    }
  }
}

z.t.describe "z.git.stats.author.footer"; {
  z.t.context "呼び出した場合"; {
    z.t.it "テーブルのフッターを表示する"; {
      z.t.mock name="z.io"

      z.git.stats.author.footer

      z.t.mock.result "└──────────────────────┴────────────┴────────────┴────────────┴────────────┘"
    }
  }
}
