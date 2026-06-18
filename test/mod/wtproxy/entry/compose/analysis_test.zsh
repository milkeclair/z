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

      local branch="feat/very-long-branch-name-for-compose-project-name"
      local branch_hash=$(print -rn -- "$branch" | sha1sum)
      branch_hash=${branch_hash%% *}

      z.wtproxy._entry.compose.name "$branch"

      z.t.expect "${#REPLY}" 63
      z.t.expect "${REPLY[-8,-1]}" "${branch_hash[1,8]}"
    }

    z.t.it "project名が長くてもhash suffixを保持する"; {
      z.t.mock name="z.wtproxy._config" behavior='
        local -A config=(project extremely_long_project_name_that_would_otherwise_remove_hash_suffix)
        z.return.hash config
      '
      local branch="feat/branch-a"
      local branch_hash=$(print -rn -- "$branch" | sha1sum)
      branch_hash=${branch_hash%% *}

      z.wtproxy._entry.compose.name "$branch"

      z.t.expect "${#REPLY}" 63
      z.t.expect "${REPLY[-8,-1]}" "${branch_hash[1,8]}"
    }

    z.t.it "先頭が同じ長いbranchでも異なるcompose project名を返す"; {
      z.t.mock name="z.wtproxy._config" behavior='
        local -A config=(project very_long_project_name_for_compose)
        z.return.hash config
      '
      local branch_a="feat/very-long-branch-name-for-compose-project-name-a"
      local branch_b="feat/very-long-branch-name-for-compose-project-name-b"

      z.wtproxy._entry.compose.name "$branch_a"
      local name_a=$REPLY

      z.wtproxy._entry.compose.name "$branch_b"
      local name_b=$REPLY

      z.is.not.eq "$name_a" "$name_b"
      z.t.expect.status.is.true
      z.t.expect "${#name_a}" 63
      z.t.expect "${#name_b}" 63
    }
  }
}
