source ${z_main}

z.t.describe "z.cls.store._ensure"; {
  z.t.context "親がallexportを設定している場合"; {
    z.t.it "allexport下で初期化しても子のZshは独立して初期化する"; {
      local -a output=()
      output=("${(@f)$(
        setopt allexport
        print -rl -- "${+z_cls_store_ready}"
        source "$z_root/test/lib/cls/fixtures/counter.zsh"
        local parent_instance=""
        z.cls.new TestCounter parent_instance
        zsh -f "$z_root/test/lib/cls/fixtures/exported-child.zsh"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 2
      z.t.expect "$output[1]" 0
      z.t.expect "$output[2]" 1
    }
  }

  z.t.context "初期化済みの場合"; {
    z.t.it "既存のクラスと状態を保持する"; {
      z.cls.store._ensure
      z_cls_classes[StorePreserved]=1

      z.cls.store._ensure

      z.t.expect "$z_cls_classes[StorePreserved]" 1

      unset 'z_cls_classes[StorePreserved]'
    }
  }

  z.t.context "既存の保存領域に所有者の管理表がない場合"; {
    z.t.it "再読込時に既存のクラスを保ちながら所有者の管理表を初期化する"; {
      (
        z.cls.store._ensure
        z_cls_classes[StoreBeforeGc]=1
        unset z_cls_owner_markers
        z.cls.store._ensure
        z.var.exists z_cls_owner_markers &&
          z.is.eq "$z_cls_classes[StoreBeforeGc]" 1
      )

      z.t.expect.status.is.true
    }
  }

  z.t.context "初期化フラグだけが残る場合"; {
    z.t.it "不足したストアを初期化する"; {
      unset z_cls_dispatch_programs
      z_cls_store_ready=1

      z.cls.store._ensure

      z.var.exists z_cls_dispatch_programs

      z.t.expect.status.is.true
    }
  }
}


z.t.describe "z.cls.store._scalar"; {
  z.t.context "空白と空値を保存する場合"; {
    z.t.it "引用して復元でき、呼出元のREPLYを保持する"; {
      () {
        z.cls.store._ensure
        local label=old
        REPLY=before

        z.cls.store._scalar declaration_ref label "two words"

        z.t.expect.reply before

        eval "$z_cls_values[declaration_ref:label]"

        z.t.expect "$label" "two words"

        z.cls.store._scalar declaration_ref label ""
        eval "$z_cls_values[declaration_ref:label]"

        z.t.expect.is.null "$label"

        unset 'z_cls_values[declaration_ref:label]'
      }
    }
  }
}
