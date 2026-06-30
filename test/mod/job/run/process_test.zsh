source ${z_main}

z.t.describe "z.job.run._prepare"; {
  z.t.context "nameとcommandがある場合"; {
    z.t.it "job directoryと初期ファイルを作る"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root

      z.job.run._prepare name=example command=z.is.not.null on_success=z.is.not.null on_failure=z.is.null # zls: ignore
      local prepare_status=$?
      local -a prepared=("${REPLY[@]}")
      local id=$prepared[1]
      local dir=$prepared[2]

      z.t.expect "$prepare_status" 0
      z.is.not.null "$id"
      z.t.expect.status.is.true
      z.t.expect "$dir" "$root/jobs/$id"
      z.dir.exists "$dir"
      z.t.expect.status.is.true

      z.job.meta._read dir="$dir"
      z.t.expect.status.is.true
      z.t.expect "$z_job_id" "$id"
      z.t.expect "$z_job_name" example
      z.t.expect "$z_job_command" z.is.not.null # zls: ignore
      z.t.expect "$z_job_on_success" z.is.not.null # zls: ignore
      z.t.expect "$z_job_on_failure" z.is.null # zls: ignore
      z.file.read path="$dir/status"
      z.t.expect.reply queued
      z.file.read path="$dir/exit"
      z.t.expect.reply ""
      z.file.exists "$dir/result"
      z.t.expect.status.is.true
      z.file.exists "$dir/stdout"
      z.t.expect.status.is.true
      z.file.exists "$dir/stderr"
      z.t.expect.status.is.true
      z.dir.remove path=$root
    }
  }
}

z.t.describe "z.job.run._spawn"; {
  z.t.context "idとdirがある場合"; {
    z.t.it "child processを起動してpidを返す"; {
      local root=/tmp/z_job_run_spawn_success_$$
      local dir=$root/jobs/job-1
      z.dir.remove path=$root
      z.dir.make path=$dir
      z.job.meta._write id=job-1 name=example command=z.is.not.null dir=$dir
      z.file.write path=$dir/status content=queued
      z.file.write path=$dir/exit content=""
      z.file.make path=$dir/result
      z.file.make path=$dir/stdout
      z.file.make path=$dir/stderr

      z.job.run._spawn id=job-1 dir=$dir
      local pid=$REPLY

      z.t.expect.status.is.true
      REPLY=$pid
      z.t.expect.reply.is.not.null

      local i=0
      local job_status=""
      while z.int.is.lt $i 20; do
        z.file.read path=$dir/status
        job_status=$REPLY
        z.is.eq "$job_status" "success" && break
        sleep 0.05
        ((i++))
      done

      REPLY=$job_status
      z.t.expect.reply success
      z.file.read path=$dir/exit
      z.t.expect.reply 0
      z.file.read path=$dir/stderr
      z.t.expect.reply ""
      z.dir.remove path=$root
    }
  }

  z.t.context "idがない場合"; {
    z.t.it "falseを返す"; {
      z.job.run._spawn dir=/tmp/z_t/job_run_spawn_missing_id # zls: ignore

      z.t.expect.status.is.false
    }
  }

  z.t.context "dirがない場合"; {
    z.t.it "falseを返す"; {
      z.job.run._spawn id=job-1 # zls: ignore

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.job.run._child"; {
  z.t.context "commandが成功した場合"; {
    z.t.it "resultとsuccess statusを保存する"; {
      local dir=/tmp/z_t/job_run_child_success/jobs/job-1
      z.dir.remove path=/tmp/z_t/job_run_child_success
      z.dir.make path=$dir
      z.t.mock name="z_job_run_test_write_result" behavior="
        z.arg.named result \"\$@\"
        local result=\$REPLY
        z.arg.named name \"\$@\"
        local name=\$REPLY
        z.file.write path=\"\$result\" content=\"result:\$name\"
      "
      z.job.meta._write id=job-1 name=example command=z_job_run_test_write_result dir=$dir
      z.file.write path=$dir/status content=queued
      z.file.write path=$dir/exit content=""
      z.file.make path=$dir/result

      z.job.run._child id=job-1 dir=$dir
      z.t.expect.status.is.true
      z.file.read path=$dir/status
      z.t.expect.reply success
      z.file.read path=$dir/exit
      z.t.expect.reply 0
      z.file.read path=$dir/result
      z.t.expect.reply result:example
    }
  }

  z.t.context "commandが失敗した場合"; {
    z.t.it "failure statusを保存する"; {
      local dir=/tmp/z_t/job_run_child_failure/jobs/job-1
      z.dir.remove path=/tmp/z_t/job_run_child_failure
      z.dir.make path=$dir
      z.t.mock name="z_job_run_test_fail" behavior="return 7"
      z.job.meta._write id=job-1 name=example command=z_job_run_test_fail dir=$dir
      z.file.write path=$dir/status content=queued
      z.file.write path=$dir/exit content=""
      z.file.make path=$dir/result

      z.job.run._child id=job-1 dir=$dir
      z.t.expect.status 7
      z.file.read path=$dir/status
      z.t.expect.reply failure
      z.file.read path=$dir/exit
      z.t.expect.reply 7
    }
  }
}
