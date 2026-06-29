source ${z_main}

z.t.describe "z.job.collect._one"; {
  z.t.context "success jobの場合"; {
    z.t.it "idを返してcleanupする"; {
      local dir=/tmp/z_t/job_collect_one_success/jobs/job-1
      z.dir.remove path=/tmp/z_t/job_collect_one_success
      z.dir.make path=$dir
      z.job.meta._write id=job-1 name=example command=z.is.not.null dir=$dir
      z.file.write path=$dir/status content=success
      z.file.write path=$dir/exit content=0

      z.job.collect._one dir=$dir
      local collect_status=$?
      local collected_id=$REPLY

      z.t.expect "$collect_status" 0
      REPLY=$collected_id
      z.t.expect.reply job-1
      z.dir.not.exists $dir
      z.t.expect.status.is.true
    }
  }

  z.t.context "queued jobの場合"; {
    z.t.it "collectしない"; {
      local dir=/tmp/z_t/job_collect_one_queued/jobs/job-1
      z.dir.remove path=/tmp/z_t/job_collect_one_queued
      z.dir.make path=$dir
      z.job.meta._write id=job-1 name=example command=z.is.not.null dir=$dir
      z.file.write path=$dir/status content=queued

      z.job.collect._one dir=$dir
      local collect_status=$?
      local collected_id=$REPLY

      z.t.expect "$collect_status" 0
      REPLY=$collected_id
      z.t.expect.reply.is.null
      z.dir.exists $dir
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

      z.job.collect._one dir=$dir
      local collect_status=$?
      local collected_id=$REPLY

      z.t.expect "$collect_status" 0
      REPLY=$collected_id
      z.t.expect.reply.is.null
      z.dir.exists $dir
      z.t.expect.status.is.true
      z.dir.remove path=$root
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

      z.job.collect._one dir=$dir
      local collect_status=$?
      local collected_id=$REPLY

      z.t.expect "$collect_status" 0
      REPLY=$collected_id
      z.t.expect.reply job-1
      z.dir.not.exists $dir
      z.t.expect.status.is.true
    }
  }

  z.t.context "callbackが失敗した場合"; {
    z.t.it "falseを返してcleanupする"; {
      local dir=/tmp/z_t/job_collect_one_callback_failure/jobs/job-1
      z.dir.remove path=/tmp/z_t/job_collect_one_callback_failure
      z.dir.make path=$dir
      z.t.mock name="z_job_collect_test_fail" behavior="return 7"
      z.job.meta._write id=job-1 name=example command=z.is.not.null on_success=z_job_collect_test_fail dir=$dir
      z.file.write path=$dir/status content=success
      z.file.write path=$dir/exit content=0

      z.job.collect._one dir=$dir
      local collect_status=$?
      local collected_id=$REPLY

      z.t.expect "$collect_status" 1
      REPLY=$collected_id
      z.t.expect.reply job-1
      z.dir.not.exists $dir
      z.t.expect.status.is.true
    }
  }
}

z.t.describe "z.job.collect._callback"; {
  z.t.context "success callbackがある場合"; {
    z.t.it "callbackを名前付き引数で呼び出す"; {
      local dir=/tmp/z_t/job_collect_callback/jobs/job-1
      local callback_file=/tmp/z_t/job_collect_callback_output
      z.dir.make path=${callback_file:h}
      z.dir.remove path=/tmp/z_t/job_collect_callback
      z.dir.make path=$dir
      z.t.mock name="z_job_collect_test_callback" behavior="
        z.arg.named id \"\$@\"
        local id=\$REPLY
        z.arg.named name \"\$@\"
        local name=\$REPLY
        z.arg.named exit_status \"\$@\"
        local exit_status=\$REPLY
        z.file.write path=\"$callback_file\" content=\"\$id|\$name|\$exit_status\" # zls: ignore
      "
      z.job.meta._write \
        id=job-1 \
        name=example \
        command=z.is.not.null \
        on_success=z_job_collect_test_callback \
        dir=$dir
      z.file.write path=$dir/exit content=0

      z.job.collect._callback dir=$dir status=success

      z.file.read path=$callback_file
      z.t.expect.reply "job-1|example|0"
    }
  }
}
