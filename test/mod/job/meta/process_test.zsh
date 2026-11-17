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

  z.t.context "空値と引用・改行・置換式を含む場合"; {
    z.t.it "全フィールドをそのまま復元し、置換式を実行しない"; {
      local dir=$(mktemp -d)
      local marker=$dir/never-created
      local id=$'job "one"\nsecond'
      local name="日本語 'job' \\ \$(print changed > $marker)"
      local command='style=double'
      local on_failure='default=x'

      {
        z.job.meta._write "id=$id" "name=$name" "command=$command" on_success= "on_failure=$on_failure" "dir=$dir"
        z.job.meta._read "dir=$dir"
        local actual=("$z_job_id" "$z_job_name" "$z_job_command" "$z_job_on_success" "$z_job_on_failure" "$z_job_dir")
        z.file.not.exists "$marker"
        local marker_status=$?

        z.t.expect "$marker_status" 0
        z.t.expect "$actual[1]" "$id"
        z.t.expect "$actual[2]" "$name"
        z.t.expect "$actual[3]" "$command"
        z.t.expect.is.null "$actual[4]"
        z.t.expect "$actual[5]" "$on_failure"
        z.t.expect "$actual[6]" "$dir"
      } always {
        z.dir.remove "path=$dir"
      }
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
