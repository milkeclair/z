source ${z_main}

z.t.describe "z.cls.store._ensure"; {
  z.t.context "親がallexportを設定している場合"; {
    z.t.it "allexportが有効な親シェルの状態を子に渡さない"; {
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

z.t.describe "z.cls.store._method"; {
  z.t.context "等号と改行を含む本体の場合"; {
    z.t.it "本体をそのまま保存し、呼出元のREPLYを保つ"; {
      () {
        local -A z_cls_bodies=() z_cls_class_methods=()
        local body=$'local value="a=b"\nREPLY=$value'
        REPLY=unchanged

        z.cls.store._method read class=WithBody body="$body"

        z.t.expect.reply unchanged
        z.t.expect "$z_cls_bodies[WithBody:read]" "$body"
        z.cls.store._names "$z_cls_class_methods[WithBody]"

        z.t.expect.reply.is.arr read
      }
    }
  }
}

z.t.describe "z.cls.store._discard"; {
  z.t.context "別のクラスにもメンバーがある場合"; {
    z.t.it "選んだクラスの未公開データだけを破棄する"; {
      () {
        local -A z_cls_class_attrs=([Draft]=count [Existing]=value)
        local -A z_cls_class_methods=([Draft]=run [Existing]=read)
        local -A z_cls_defaults=([Draft:count]=0 [Existing:value]=1)
        local -A z_cls_bodies=([Draft:run]=':' [Existing:read]='REPLY=1')

        z.cls.store._discard Draft

        z.var.exists 'z_cls_class_attrs[Draft]'
        z.t.expect.status.is.false

        z.var.exists 'z_cls_class_methods[Draft]'
        z.t.expect.status.is.false

        z.var.exists 'z_cls_defaults[Draft:count]'
        z.t.expect.status.is.false

        z.var.exists 'z_cls_bodies[Draft:run]'
        z.t.expect.status.is.false

        z.t.expect "$z_cls_defaults[Existing:value]" 1
        z.t.expect "$z_cls_bodies[Existing:read]" 'REPLY=1'
      }
    }
  }
}
