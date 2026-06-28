source ${z_main}


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
