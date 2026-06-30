source ${z_main}

z.t.describe "z.job.file._root"; {
  z.t.context "呼び出された場合"; {
    z.t.it "rootを返す"; {
      z.job.file._root

      z.t.expect.reply "/tmp/z/job/$$"
    }
  }
}

z.t.describe "z.job.file._jobs"; {
  z.t.context "呼び出された場合"; {
    z.t.it "jobsディレクトリのpathを返す"; {
      z.job.file._root
      local root=$REPLY

      z.job.file._jobs

      z.t.expect.reply "$root/jobs"
    }
  }
}

z.t.describe "z.job.file._dir"; {
  z.t.context "idがある場合"; {
    z.t.it "job idに対応するdirectory pathを返す"; {
      z.job.file._root
      local root=$REPLY

      z.job.file._dir id=job-id

      z.t.expect.reply "$root/jobs/job-id"
    }
  }

  z.t.context "idがない場合"; {
    z.t.it "falseを返す"; {
      z.job.file._dir # zls: ignore

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.job.file._path"; {
  z.t.context "idとnameがある場合"; {
    z.t.it "job file pathを返す"; {
      z.job.file._root
      local root=$REPLY

      z.job.file._path id=job-id name=status

      z.t.expect.reply "$root/jobs/job-id/status"
    }
  }

  z.t.context "idがない場合"; {
    z.t.it "falseを返す"; {
      z.job.file._path name=status # zls: ignore

      z.t.expect.status.is.false
    }
  }

  z.t.context "nameがない場合"; {
    z.t.it "falseを返す"; {
      z.job.file._path id=job-id # zls: ignore

      z.t.expect.status.is.false
    }
  }
}
