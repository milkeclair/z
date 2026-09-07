source ${z_main}

z.t.describe "z.job.status"; {
  z.t.context "status fileがある場合"; {
    z.t.it "statusを標準出力とREPLYに返す"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      local dir=$root/jobs/job-1
      z.dir.make path=$dir
      z.job.meta._write id=job-1 name=example command=z.is.not.null dir=$dir
      z.file.write path=$dir/status content=success

      z.job.status id=job-1 > "$root/stdout"
      local result_code=$?
      local result_reply=$REPLY
      local result_stdout=$(< "$root/stdout")

      z.t.expect "$result_code" "0"
      z.t.expect "$result_reply" "success"
      z.t.expect "$result_stdout" "success"
    }
  }

  z.t.context "status fileがない場合"; {
    z.t.it "標準出力へ出さずfalseを返す"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      z.dir.make path=$root

      z.job.status id=missing > "$root/stdout"

      z.t.expect.status.is.false
      [[ ! -s "$root/stdout" ]]
      z.t.expect.status.is.true
    }
  }

  z.t.context "idを指定しない場合"; {
    z.t.it "標準出力へ出さずfalseを返す"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      z.dir.make path=$root

      z.job.status > "$root/stdout" # zls: ignore

      z.t.expect.status.is.false
      [[ ! -s "$root/stdout" ]]
      z.t.expect.status.is.true
    }
  }
}

z.t.describe "z.job.list"; {
  z.t.context "jobがある場合"; {
    z.t.it "job一覧を標準出力とREPLYに返す"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      local dir=$root/jobs/job-1
      z.dir.make path=$dir
      z.job.meta._write id=job-1 name=example command=z.is.not.null dir=$dir
      z.file.write path=$dir/status content=running

      z.job.list > "$root/stdout"
      local result_reply=$REPLY
      local result_stdout=$(< "$root/stdout")

      z.t.expect "$result_reply" $'job-1\texample\trunning'
      z.t.expect "$result_stdout" $'job-1\texample\trunning'
    }
  }

  z.t.context "jobsディレクトリがない場合"; {
    z.t.it "標準出力へ出さず空のREPLYを返す"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      z.dir.make path=$root

      z.job.list > "$root/stdout"
      local result_reply=$REPLY

      z.t.expect "$result_reply" ""
      [[ ! -s "$root/stdout" ]]
      z.t.expect.status.is.true
    }
  }

  z.t.context "jobsディレクトリが空の場合"; {
    z.t.it "標準出力へ出さず空のREPLYを返す"; {
      z.job.file._root
      local root=$REPLY
      z.dir.remove path=$root
      z.dir.make path=$root/jobs

      z.job.list > "$root/stdout"
      local result_reply=$REPLY

      z.t.expect "$result_reply" ""
      [[ ! -s "$root/stdout" ]]
      z.t.expect.status.is.true
    }
  }
}
