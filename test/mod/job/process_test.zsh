source ${z_main}

z.t.describe "z.job.run"; {
  z.t.context "同名jobを起動する場合"; {
    z.t.it "queueへ積む"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      z.t.mock name="z.job.run._spawn" behavior="z.return 999999"

      z.job.run name=example command=z.is.not.null # zls: ignore
      local first_id=$REPLY
      z.job.run name=example command=z.is.not.null # zls: ignore
      local second_id=$REPLY

      z.is.not.eq "$first_id" "$second_id"
      z.t.expect.status.is.true
      z.job.list
      local jobs_text=$REPLY
      z.t.expect.includes "$jobs_text" "$first_id"
      z.t.expect.includes "$jobs_text" "$second_id"
    }
  }

  z.t.context "spawnに失敗した場合"; {
    z.t.it "失敗してcleanupする"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      z.t.mock name="z.job.run._spawn" behavior="return 1"

      z.job.run name=example command=z.is.not.null # zls: ignore
      z.t.expect.status.is.false
      z.job.list
      z.t.expect.reply.is.null
    }
  }

  z.t.context "precmd登録に失敗した場合"; {
    z.t.it "失敗してcleanupし、spawnしない"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      z.t.mock name="z.job.precmd._register" behavior="return 1"
      z.t.mock name="z.job.run._spawn" behavior="z.return 999999"

      z.job.run name=example command=z.is.not.null # zls: ignore

      z.t.expect.status.is.false skip_unmock=true
      z.job.list
      z.t.expect.reply.is.null skip_unmock=true
      z.t.mock.result name="z.job.run._spawn"
      z.t.expect.reply ""
    }
  }
}

z.t.describe "z.job.collect"; {
  z.t.context "callbackがある成功jobの場合"; {
    z.t.it "callbackを名前付き引数で呼び出してcleanupする"; {
      z.job.file._root
      local root=$REPLY
      local callback_file=/tmp/z_t/job_collect_success_callback
      z.dir.make path=${callback_file:h}
      z.dir.remove path=$root
      local dir=$root/jobs/job-1
      z.dir.make path=$dir
      z.t.mock name="z_job_test_callback" behavior="
        z.arg.named id \"\$@\"
        local id=\$REPLY
        z.arg.named name \"\$@\"
        local name=\$REPLY
        z.arg.named result \"\$@\"
        local result=\$REPLY
        z.arg.named exit_status \"\$@\"
        local exit_status=\$REPLY
        z.file.write path=\"$callback_file\" content=\"\$id|\$name|\$exit_status|\$result\" # zls: ignore
      "
      z.job.meta._write id=job-1 name=example command=z.is.not.null on_success=z_job_test_callback dir=$dir
      z.file.write path=$dir/status content=success
      z.file.write path=$dir/exit content=0
      z.file.make path=$dir/result

      z.job.collect
      z.t.expect.reply job-1
      z.file.read path=$callback_file
      z.t.expect.reply.includes "job-1|example|0|$dir/result"
      z.dir.not.exists $dir
      z.t.expect.status.is.true
    }
  }

  z.t.context "callbackがないjobの場合"; {
    z.t.it "cleanupする"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      local dir=$root/jobs/job-1
      z.dir.make path=$dir
      z.job.meta._write id=job-1 name=example command=z.is.not.null dir=$dir
      z.file.write path=$dir/status content=success
      z.file.write path=$dir/exit content=0

      z.job.collect
      z.t.expect.reply job-1
      z.dir.not.exists $dir
      z.t.expect.status.is.true
    }
  }

  z.t.context "running jobのpidが生きている場合"; {
    z.t.it "collectしない"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      local dir=$root/jobs/job-1
      z.dir.make path=$dir
      z.job.meta._write id=job-1 name=example command=z.is.not.null dir=$dir
      z.file.write path=$dir/status content=running
      z.file.write path=$dir/pid content=$$

      z.job.collect
      z.t.expect.reply.is.null
      z.dir.exists $dir
      z.t.expect.status.is.true
    }
  }

  z.t.context "running jobのpidが存在しない場合"; {
    z.t.it "failureとしてcollectしてcleanupする"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      local dir=$root/jobs/job-1
      z.dir.make path=$dir
      z.job.meta._write id=job-1 name=example command=z.is.not.null dir=$dir
      z.file.write path=$dir/status content=running
      z.file.write path=$dir/pid content=999999999

      z.job.collect

      z.t.expect.reply job-1
      z.dir.not.exists $dir
      z.t.expect.status.is.true
    }
  }
}

z.t.describe "z.job.cancel"; {
  z.t.context "jobが存在する場合"; {
    z.t.it "job directoryを削除する"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      local dir=$root/jobs/job-1
      z.dir.make path=$dir
      z.job.meta._write id=job-1 name=example command=z.is.not.null dir=$dir
      z.file.write path=$dir/pid content=""

      z.job.cancel id=job-1

      z.dir.not.exists $dir
      z.t.expect.status.is.true
    }
  }

  z.t.context "pidのprocessが生きている場合"; {
    z.t.it "processをkillしてjob directoryを削除する"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      local dir=$root/jobs/job-1
      z.dir.make path=$dir
      z.job.meta._write id=job-1 name=example command=z.is.not.null dir=$dir
      sleep 5 &!
      local pid=$!
      z.file.write path=$dir/pid content=$pid

      kill -0 "$pid" >/dev/null 2>&1
      z.t.expect.status.is.true

      z.job.cancel id=job-1
      z.t.expect.status.is.true

      local i=0
      while z.int.is.lt $i 20 && kill -0 "$pid" >/dev/null 2>&1; do
        sleep 0.05
        ((i++))
      done
      kill -0 "$pid" >/dev/null 2>&1
      local process_alive_status=$?
      z.int.is.zero $process_alive_status && kill "$pid" >/dev/null 2>&1

      z.int.is.not.zero $process_alive_status
      z.t.expect.status.is.true
      z.dir.not.exists $dir
      z.t.expect.status.is.true
    }
  }

  z.t.context "idがない場合"; {
    z.t.it "falseを返す"; {
      z.job.cancel # zls: ignore

      z.t.expect.status.is.false
    }
  }

  z.t.context "job directoryがない場合"; {
    z.t.it "falseを返す"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root

      z.job.cancel id=missing

      z.t.expect.status.is.false
    }
  }
}
