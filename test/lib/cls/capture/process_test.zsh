source ${z_main}

z.t.describe "z.cls.capture.start"; {
  z.t.context "DEBUG捕捉を開始する場合"; {
    z.t.it "メソッド名と呼出元を保持する"; {
      z.cls.store.ensure
      z.t.mock name=z.cls.capture.debug

      z.cls.capture.start captured_method test_stack test_file 0
      local installed_debug=${+functions[TRAPDEBUG]}
      local captured_name=$z_cls_capture_method
      local captured_stack=$z_cls_capture_stack
      z.cls.capture.stop

      z.t.expect "$installed_debug" 1
      z.t.expect "$captured_name" captured_method
      z.t.expect "$captured_stack" test_stack
    }
  }
}

z.t.describe "z.cls.capture.stop"; {
  z.t.context "DEBUG捕捉を終了する場合"; {
    z.t.it "元の関数形式トラップを復元する"; {
      z.cls.store.ensure
      z.t.mock name=z.cls.capture.debug
      TRAPDEBUG() {
        return 0
      }
      local original_debug=$functions[TRAPDEBUG]
      z.cls.capture.start captured_method test_stack test_file 0

      z.cls.capture.stop

      z.t.expect "$functions[TRAPDEBUG]" "$original_debug"
      z.t.expect "$z_cls_capture_method" ''

      unfunction TRAPDEBUG
    }
  }
}

z.t.describe "z.cls.capture.debug"; {
  z.t.context "通常の本体を捕捉する場合"; {
    z.t.it "コマンドを保存してerrexitで実行を抑制する"; {
      z.cls.store.ensure
      z_cls_capture_method=record
      z_cls_capture_stack=''
      z_cls_capture_body=''

      z.cls.capture.debug 'print literal'
      local captured_errexit=$options[errexit]
      unsetopt errexit

      z.t.expect "$z_cls_capture_body" $'print literal\n'
      z.t.expect "$captured_errexit" on

      z_cls_capture_method=''
    }
  }
}
