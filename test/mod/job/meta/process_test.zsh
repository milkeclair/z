source ${z_main}

z.t.describe "z.job.meta._write"; {
  z.t.context "metadataを書き込む場合"; {
    z.t.it "sourceできる形式で保存する"; {
      local dir=/tmp/z_t/job_meta_write/jobs/job-1
      z.dir.remove path=/tmp/z_t/job_meta_write
      z.dir.make path=$dir

      z.job.meta._write id=job-1 name=example command=z.is.not.null on_success=z.is.not.null dir=$dir
      source "$dir/meta"

      z.t.expect "$z_job_id" "job-1"
      z.t.expect "$z_job_name" "example"
      z.t.expect "$z_job_command" "z.is.not.null"
      z.t.expect "$z_job_on_success" "z.is.not.null"
    }
  }
}

z.t.describe "z.job.meta._read"; {
  z.t.context "metadata fileがある場合"; {
    z.t.it "metadataを変数へ読み込む"; {
      local dir=/tmp/z_t/job_meta_read/jobs/job-1
      z.dir.remove path=/tmp/z_t/job_meta_read
      z.dir.make path=$dir
      z.file.write path=$dir/meta content=""
      z.file.write.last path=$dir/meta content="z_job_id='job-1'"
      z.file.write.last path=$dir/meta content="z_job_name='example'"
      z.file.write.last path=$dir/meta content="z_job_command='z.is.not.null'"
      z.file.write.last path=$dir/meta content="z_job_on_success=''"
      z.file.write.last path=$dir/meta content="z_job_on_failure=''"
      z.file.write.last path=$dir/meta content="z_job_dir='$dir'"

      z.job.meta._read dir=$dir

      z.t.expect "$z_job_id" "job-1"
      z.t.expect "$z_job_name" "example"
      z.t.expect "$z_job_command" "z.is.not.null"
    }
  }

  z.t.context "dirがない場合"; {
    z.t.it "falseを返す"; {
      z.job.meta._read # zls: ignore

      z.t.expect.status.is.false
    }
  }
}
