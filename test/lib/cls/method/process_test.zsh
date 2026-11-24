source ${z_main}

z.t.describe "z.cls.method.defined"; {
  z.t.context "メソッドを登録できなかった場合"; {
    z.t.it "メソッドを登録できなければ終了コード1を返す"; {
      z_cls_capture_done_result=1

      z.cls.method.defined

      z.t.expect.status.is.false
    }

    z.t.it "終了コードを返した後は結果を消去する"; {
      z_cls_capture_done_result=1
      z.cls.method.defined

      z.var.exists z_cls_capture_done_result

      z.t.expect.status.is.false
    }
  }

  z.t.context "DEBUGトラップが呼出元のresultに代入する場合"; {
    z.t.it "DEBUGトラップの代入で終了コードが変わらない"; {
      local -a output=()
      output=("${(@f)$(
        local result=before
        z_cls_capture_done_result=1
        TRAPDEBUG() {
          if [[ $funcstack[2] == z.cls.method.defined ]]; then
            result=62
          fi
          return 0
        }

        z.cls.method.defined
        local done_status=$?
        unfunction TRAPDEBUG
        print -rl -- "$done_status" "$result"
      )}")

      z.t.expect "$output[1]" 1
      z.t.expect "$output[2]" 62
    }
  }

  z.t.context "終了コードが記録されていない場合"; {
    z.t.it "単独で呼び出した終了マーカーは0を返す"; {
      unset z_cls_capture_done_result

      z.cls.method.defined

      z.t.expect.status.is.true
    }
  }
}
