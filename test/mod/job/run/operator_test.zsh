source ${z_main}


z.t.describe "z.job.run._validate"; {
  z.t.context "nameとcommandがありcallbackも存在する場合"; {
    z.t.it "trueを返す"; {
      z.job.run._validate name=example command=z.is.not.null on_success=z.is.not.null on_failure=z.is.null # zls: ignore

      z.t.expect.status.is.true
    }
  }

  z.t.context "nameがない場合"; {
    z.t.it "falseを返す"; {
      z.job.run._validate command=z.is.not.null # zls: ignore

      z.t.expect.status.is.false
    }
  }

  z.t.context "commandが存在しない場合"; {
    z.t.it "falseを返す"; {
      z.job.run._validate name=example command=z_job_missing_command # zls: ignore

      z.t.expect.status.is.false
    }
  }

  z.t.context "on_successが存在しない場合"; {
    z.t.it "falseを返す"; {
      z.job.run._validate name=example command=z.is.not.null on_success=z_job_missing_callback # zls: ignore

      z.t.expect.status.is.false
    }
  }

  z.t.context "on_failureが存在しない場合"; {
    z.t.it "falseを返す"; {
      z.job.run._validate name=example command=z.is.not.null on_failure=z_job_missing_callback # zls: ignore

      z.t.expect.status.is.false
    }
  }
}
