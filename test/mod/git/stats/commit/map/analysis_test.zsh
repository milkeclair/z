source ${z_main}

z.t.describe "z.git.stats.commit.map.split"; {
  z.t.context "entryを渡した場合"; {
    z.t.it "entryをauthor, details, commit_countに分割して返す"; {
      z.git.stats.commit.map.split entry="milkeclair:1000 500:50"

      local -A expected=(
        [author]="milkeclair"
        [commit_count]="50"
        [inserted]="1000"
        [deleted]="500"
        [total]="1500"
      )
      local -A result=($REPLY)
      z.t.expect "$result" "$expected"
      unset result
      unset expected
    }
  }

  z.t.context "entryのdetailsが0 0の場合"; {
    z.t.it "totalも0として返す"; {
      z.git.stats.commit.map.split entry="milkeclair:0 0:10"

      local -A expected=(
        [author]="milkeclair"
        [commit_count]="10"
        [inserted]="0"
        [deleted]="0"
        [total]="0"
      )
      local -A result=($REPLY)
      z.t.expect "$result" "$expected"
      unset result
      unset expected
    }
  }
}

z.t.describe "z.git.stats.commit.map.distinct"; {
  z.t.context "重複するエントリーがある場合"; {
    z.t.it "commit_count, inserted, deletedが同じエントリーを1つだけ返す"; {
      local commit_map=(
        "Alice:1000 500:50"
        "Bob:800 300:40"
        "Alice:1000 500:50" # duplicate
      )

      z.git.stats.commit.map.distinct "${commit_map[@]}"

      local expected=(
        "Alice:1000 500:50"
        "Bob:800 300:40"
      )
      z.t.expect.reply.is.arr "${expected[@]}"
      unset expected
    }
  }

  z.t.context "重複するエントリーがない場合"; {
    z.t.it "すべてのエントリーを返す"; {
      local commit_map=(
        "Alice:1000 500:50"
        "Bob:800 300:40"
        "Charlie:600 200:30"
      )

      z.git.stats.commit.map.distinct "${commit_map[@]}"

      local expected=(
        "Alice:1000 500:50"
        "Bob:800 300:40"
        "Charlie:600 200:30"
      )
      z.t.expect.reply.is.arr "${expected[@]}"
      unset expected
    }
  }
}
