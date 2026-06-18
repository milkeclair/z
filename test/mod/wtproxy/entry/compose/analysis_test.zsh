source ${z_main}

z.t.describe "z.wtproxy._entry.compose.name"; {
  z.t.context "branch labelを指定した場合"; {
    z.t.it "project名とbranch slugとhashからcompose project名を返す"; {
      z.t.mock name="z.wtproxy._config" behavior='
        local -A config=(project sample)
        z.return.hash config
      '
      local branch=feat/example
      local branch_hash=$(print -rn -- "$branch" | sha1sum)
      branch_hash=${branch_hash%% *}

      z.wtproxy._entry.compose.name "$branch"

      z.t.expect.reply "sample_feat_example_${branch_hash[1,8]}"
    }
  }

  z.t.context "生成名が長い場合"; {
    z.t.it "63文字以内に切り詰める"; {
      z.t.mock name="z.wtproxy._config" behavior='
        local -A config=(project very_long_project_name_for_compose)
        z.return.hash config
      '

      z.wtproxy._entry.compose.name "feat/very-long-branch-name-for-compose-project-name"

      z.t.expect "${#REPLY}" 63
    }
  }
}
