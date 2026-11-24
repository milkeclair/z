source ${z_main}

z.t.describe "z.cls.method.defined"; {
  z.t.context "捕捉結果がある場合"; {
    z.t.it "終了状態を返して消費する"; {
      z_cls_capture_done_result=7

      z.cls.method.defined

      z.t.expect.status 7

      z.var.exists z_cls_capture_done_result

      z.t.expect.status.is.false
    }
  }

  z.t.context "DEBUGトラップが呼出元のresultに代入する場合"; {
    z.t.it "捕捉結果は変わらず、トラップの代入は呼出元へ届く"; {
      local -a output=()
      output=("${(@f)$(
        local result=before
        z_cls_capture_done_result=7
        TRAPDEBUG() {
          if [[ $funcstack[2] == z.cls.method.defined && $ZSH_DEBUG_CMD == 'unset z_cls_capture_done_result' ]]; then
            result=62
          fi
          return 0
        }

        z.cls.method.defined
        local done_status=$?
        unfunction TRAPDEBUG
        print -rl -- "$done_status" "$result"
      )}")

      z.t.expect.status.is.true
      z.t.expect "$output[1]" 7
      z.t.expect "$output[2]" 62
    }
  }

  z.t.context "捕捉結果がない場合"; {
    z.t.it "成功する"; {
      unset z_cls_capture_done_result

      z.cls.method.defined

      z.t.expect.status.is.true
    }
  }
}
