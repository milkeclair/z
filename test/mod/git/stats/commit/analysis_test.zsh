source ${z_main}

z.t.describe "z.git.stats.commit.count"; {
  z.t.context "authorを渡した場合"; {
    z.t.it "そのauthorのコミット数を返す"; {
      local expected=42
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "log --oneline --author=milkeclair"; then
          # ... (simulate 42 commits)
          for i in {1..42}; do
            z.io "$i commit message"
          done
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.stats.commit.count milkeclair

      z.t.expect.reply $expected
      unset expected
    }
  }

  z.t.context "authorが存在しない場合"; {
    z.t.it "0を返す"; {
      local expected=0
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "log --oneline --author=unknown"; then
          # no commits for this author
          return 0
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.stats.commit.count unknown

      z.t.expect.reply $expected
      unset expected
    }
  }

  z.t.context "authorにスペースが含まれる場合"; {
    z.t.it "正しくスペースを扱う"; {
      local expected=5
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "log --oneline --author=John Doe"; then
          for i in {1..5}; do
            z.io "$i commit message"
          done
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.stats.commit.count "John Doe"

      z.t.expect.reply $expected
      unset expected
    }
  }
}
