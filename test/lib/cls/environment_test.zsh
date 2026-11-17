source ${z_main}

# オプションを隔離した処理から結果を受け取り、検証は親のテストで行う。

z.t.describe "z.clsのシェル設定"; {
  z.t.context "定義時のオプションを変更する場合"; {
    z.t.it "localoptionsの設定を保持してメソッドを呼び出せる"; {
      local -a output=()
      output=("${(@f)$(
        setopt localoptions
        local before="$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        source "$z_root/test/lib/cls/counter.zsh"
        print -rl -- "$?" "$before" "$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        local first=""
        z.cls.new TestCounter first
        first.increment
        print -rl -- "$REPLY"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 4
      z.t.expect "$output[1]" 0
      z.t.expect "$output[3]" "$output[2]"
      z.t.expect "$output[4]" 1
    }

    z.t.it "localtrapsの設定を保持してメソッドを呼び出せる"; {
      local -a output=()
      output=("${(@f)$(
        setopt localtraps
        local before="$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        source "$z_root/test/lib/cls/counter.zsh"
        print -rl -- "$?" "$before" "$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        local first=""
        z.cls.new TestCounter first
        first.increment
        print -rl -- "$REPLY"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 4
      z.t.expect "$output[1]" 0
      z.t.expect "$output[3]" "$output[2]"
      z.t.expect "$output[4]" 1
    }

    z.t.it "nodebugbeforecmdの設定を保持してメソッドを呼び出せる"; {
      local -a output=()
      output=("${(@f)$(
        setopt nodebugbeforecmd
        local before="$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        source "$z_root/test/lib/cls/counter.zsh"
        print -rl -- "$?" "$before" "$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        local first=""
        z.cls.new TestCounter first
        first.increment
        print -rl -- "$REPLY"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 4
      z.t.expect "$output[1]" 0
      z.t.expect "$output[3]" "$output[2]"
      z.t.expect "$output[4]" 1
    }

    z.t.it "複数の設定を同時に保持してメソッドを呼び出せる"; {
      local -a output=()
      output=("${(@f)$(
        setopt localoptions localtraps nodebugbeforecmd
        local before="$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        source "$z_root/test/lib/cls/counter.zsh"
        print -rl -- "$?" "$before" "$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        local first=""
        z.cls.new TestCounter first
        first.increment
        print -rl -- "$REPLY"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 4
      z.t.expect "$output[1]" 0
      z.t.expect "$output[3]" "$output[2]"
      z.t.expect "$output[4]" 1
    }

    z.t.it "functionargzeroが無効でもメソッドを呼び出せる"; {
      local -a output=()
      output=("${(@f)$(
        setopt nofunctionargzero
        local before="$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        source "$z_root/test/lib/cls/counter.zsh"
        print -rl -- "$?" "$before" "$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        local first=""
        z.cls.new TestCounter first
        first.increment
        print -rl -- "$REPLY"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 4
      z.t.expect "$output[1]" 0
      z.t.expect "$output[3]" "$output[2]"
      z.t.expect "$output[4]" 1
    }
  }

  z.t.context "実体を操作する際のオプションを変更する場合"; {
    z.t.it "nounset下でコピーした参照の状態共有と削除ができる"; {
      local -a output=()
      output=("${(@f)$(
        setopt nounset
        source "$z_root/test/lib/cls/counter.zsh"
        local counter=""
        z.cls.new TestCounter counter
        local -r other=$counter
        "$other.increment"
        counter.count.get
        print -rl -- "$REPLY"
        counter.add 4
        "$other.value"
        print -rl -- "$REPLY"
        z.cls.delete other
        print -rl -- "${+functions[$counter.value]}"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 3
      z.t.expect "$output[1]" 1
      z.t.expect "$output[2]" 5
      z.t.expect "$output[3]" 0
    }

    z.t.it "errexit下で生成した関数と状態を削除する"; {
      local -a output=()
      output=("${(@f)$(
        setopt errexit
        source "$z_root/test/lib/cls/counter.zsh"
        local counter=""
        z.cls.new TestCounter counter
        counter.increment
        z.cls.delete counter
        print -rl -- "${#z_cls_instances}" "${+functions[counter.increment]}"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 2
      z.t.expect "$output[1]" 0
      z.t.expect "$output[2]" 0
    }

    z.t.it "allexport下で初期化しても子のZshは独立して初期化する"; {
      local -a output=()
      output=("${(@f)$(
        setopt allexport
        print -rl -- "${+z_cls_store_ready}"
        source "$z_root/test/lib/cls/counter.zsh"
        local parent_instance=""
        z.cls.new TestCounter parent_instance
        zsh -f "$z_root/test/lib/cls/exported-child.zsh"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 2
      z.t.expect "$output[1]" 0
      z.t.expect "$output[2]" 1
    }
  }
}
