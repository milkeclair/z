source ${z_main}

z.t.describe "z.completion.cache._build"; {
  z.t.context "cache構築後にdoc探索が失敗した場合"; {
    z.t.it "cacheからdocsを返す"; {
      z.t.mock name="z.completion.cache.build._docs" behavior='
        z_completion_docs=()
        z_completion_docs[z.arg.get]="get the argument at the specified index" # zls: ignore
      '
      z.completion.cache._build
      z.t.mock name="z.help._find_docs" behavior="return 1"

      z.completion.docs._get z.arg.get # zls: ignore
      local docs=$REPLY

      z.t.expect.includes "$docs" "get the argument at the specified index"
      z.t.mock.result name="z.help._find_docs"
      z.t.expect.reply ""
    }
  }

  z.t.context "cacheがreadyでdocsがない関数を指定した場合"; {
    z.t.it "docs探索に戻らない"; {
      z_completion_docs=()
      z_completion_cache_ready=true
      z.t.mock name="z.help._find_docs" behavior="return 1"

      z.completion.docs._get z.arg

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.help._find_docs"
      z.t.expect.reply ""
    }
  }
}

z.t.describe "z.completion.cache._cancel"; {
  z.t.context "未完了の補完jobがある場合"; {
    for job_state in queued running; do
      z.t.it "${job_state}のjobだけを取り消してIDを破棄する"; {
        local z_completion_cache_job_id=cache-job
        local -a cancelled=()
        z.t.mock name="z.job.status" behavior="z.return $job_state"
        z.t.mock name="z.job.cancel" behavior='cancelled+=("$*"); return 0'

        z.completion.cache._cancel
        local remaining=$z_completion_cache_job_id

        z.t.expect.status.is.true skip_unmock=true
        z.t.expect "$cancelled" "id=cache-job" skip_unmock=true
        z.t.expect.is.null "$remaining"
      }
    done
  }

  z.t.context "完了済みまたは回収済みの場合"; {
    for job_state in success failure; do
      z.t.it "${job_state}のPIDをkillしない"; {
        local z_completion_cache_job_id=cache-job
        local -a cancelled=()
        z.t.mock name="z.job.status" behavior="z.return $job_state"
        z.t.mock name="z.job.cancel" behavior='cancelled+=("$*"); return 0'

        z.completion.cache._cancel
        local remaining=$z_completion_cache_job_id

        z.t.expect.status.is.true skip_unmock=true
        z.t.expect "$cancelled" "" skip_unmock=true
        z.t.expect.is.null "$remaining"
      }
    done

    z.t.it "回収済みのIDでも成功する"; {
      local z_completion_cache_job_id=collected-job
      z.t.mock name="z.job.status" behavior="return 1"

      z.completion.cache._cancel

      z.t.expect.status.is.true skip_unmock=true
      z.t.expect.is.null "$z_completion_cache_job_id"
    }
  }

  z.t.context "補完jobがない場合"; {
    z.t.it "他のjobに触れず成功する"; {
      local z_completion_cache_job_id=""
      local -a inspected=()
      z.t.mock name="z.job.status" behavior='inspected+=("$*"); return 1'

      z.completion.cache._cancel

      z.t.expect.status.is.true skip_unmock=true
      z.t.expect "$inspected" ""
    }
  }
}
