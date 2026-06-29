source ${z_main}

z.t.describe "z.job.is.running"; {
  z.t.context "pidが生きているrunning jobの場合"; {
    z.t.it "trueを返す"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      local dir=$root/jobs/job-1
      z.dir.make path=$dir
      z.job.meta._write id=job-1 name=example command=z.is.not.null dir=$dir
      z.file.write path=$dir/status content=running
      z.file.write path=$dir/pid content=$$

      z.job.is.running id=job-1

      z.t.expect.status.is.true
    }
  }

  z.t.context "statusがrunningではない場合"; {
    z.t.it "falseを返す"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      local dir=$root/jobs/job-1
      z.dir.make path=$dir
      z.job.meta._write id=job-1 name=example command=z.is.not.null dir=$dir
      z.file.write path=$dir/status content=success
      z.file.write path=$dir/pid content=$$

      z.job.is.running id=job-1

      z.t.expect.status.is.false
    }
  }
}
