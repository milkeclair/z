source ${z_main}

z.t.describe "z.completion.enable"; {
  z.t.context "補完を使用しないシェルの場合"; {
    z.t.it "名前取得・補完登録・job起動をせず成功する"; {
      local -a completion_calls=()
      z.t.mock name="z.completion.is._interactive" behavior="return 1"
      z.t.mock name="z.completion.cache.build._names" behavior='completion_calls+=(names); return 0'
      z.t.mock name="z.completion.compdef._ignore_private" behavior='completion_calls+=(ignore_private); return 0'
      z.t.mock name="z.completion.compdef._register" behavior='completion_calls+=(register); return 0'
      z.t.mock name="z.job.run" behavior='completion_calls+=(job); return 0'

      z.completion.enable

      z.t.expect.status.is.true
      z.t.expect "$completion_calls" ""
    }
  }

  z.t.context "jobを起動する場合"; {
    z.t.it "queueへ積む"; {
      z.t.mock name="z.completion.is._interactive" behavior="return 0"
      z.t.mock name="z.completion.compdef._ignore_private" behavior="return 0"
      z.t.mock name="z.completion.compdef._register" behavior="return 0"
      z.t.mock name="z.job.run" behavior='z.return "$*"'

      z.completion.enable
      local args_text=$REPLY

      z.t.expect.includes "$args_text" "name=completion-cache" skip_unmock=true
      z.t.expect.includes "$args_text" "command=z.completion.cache.build._result" skip_unmock=true
      z.t.expect.includes "$args_text" "on_success=z.completion.cache.load._result" skip_unmock=true
      z.t.expect.excludes "$args_text" "on_failure="
    }
  }

  z.t.context "private除外設定に失敗した場合"; {
    z.t.it "jobを起動しない"; {
      z.t.mock name="z.completion.is._interactive" behavior="return 0"
      z.t.mock name="z.completion.compdef._ignore_private" behavior="return 1"
      z.t.mock name="z.completion.compdef._register" behavior="return 0"
      z.t.mock name="z.job.run" behavior="z.return job-id"

      z.completion.enable

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.job.run"
      z.t.expect.reply ""
    }
  }

  z.t.context "compdef登録に失敗した場合"; {
    z.t.it "jobを起動しない"; {
      z.t.mock name="z.completion.is._interactive" behavior="return 0"
      z.t.mock name="z.completion.compdef._ignore_private" behavior="return 0"
      z.t.mock name="z.completion.compdef._register" behavior="return 1"
      z.t.mock name="z.job.run" behavior="z.return job-id"

      z.completion.enable

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.job.run"
      z.t.expect.reply ""
    }
  }
}
