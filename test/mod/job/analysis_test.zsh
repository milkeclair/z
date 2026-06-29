source ${z_main}

z.t.describe "z.job.status"; {
  z.t.context "status fileがある場合"; {
    z.t.it "status fileの内容を返す"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      local dir=$root/jobs/job-1
      z.dir.make path=$dir
      z.job.meta._write id=job-1 name=example command=z.is.not.null dir=$dir
      z.file.write path=$dir/status content=success

      z.job.status id=job-1

      z.t.expect.reply success
    }
  }

  z.t.context "status fileがない場合"; {
    z.t.it "falseを返す"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root

      z.job.status id=missing

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.job.list"; {
  z.t.context "jobがある場合"; {
    z.t.it "job一覧を返す"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      local dir=$root/jobs/job-1
      z.dir.make path=$dir
      z.job.meta._write id=job-1 name=example command=z.is.not.null dir=$dir
      z.file.write path=$dir/status content=running

      z.job.list

      z.t.expect.reply $'job-1\texample\trunning'
    }
  }
}
