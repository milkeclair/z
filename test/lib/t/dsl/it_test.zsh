source "$z_main"

z.t.describe "z.t.it"; {
  z.t.context "親階層のskip状態が異なる場合"; {
    z.t.it "見出しとテスト件数とpending記録を更新する"; {
      for skip_level in none describe context; do
        local observed=$(
          () {
            local -a z_t_logs=(suite context)
            local -a z_t_pending_records=()
            local -A z_t_current_idx=(describe 1 context 2 it 0)
            local -A z_t_states=(skip_describe false skip_context false skip_it true compact false tests 0 pendings 0)
            [[ "$skip_level" == describe ]] && z_t_states[skip_describe]=true
            [[ "$skip_level" == context ]] && z_t_states[skip_context]=true

            z.t.it "example"

            print -r -- "$z_t_logs[3]"
            print -r -- "$z_t_current_idx[it] $z_t_states[tests] $z_t_states[pendings] $z_t_states[skip_it]"
            print -r -- "$z_t_pending_records"
          }
        )

        if [[ "$skip_level" == none ]]; then
          z.t.expect "$observed" $'\033[32m      example\033[0m\n3 1 0 false'
        else
          z.t.expect "$observed" $'\033[33m      example\033[0m\n3 1 1 true\n1:2:3'
        fi
      done
    }
  }
}

z.t.describe "z.t.xit"; {
  z.t.context "テストをpendingにする場合"; {
    z.t.it "黄色の見出しとpending記録を追加する"; {
      local observed=$(
        () {
          local -a z_t_logs=(suite context)
          local -a z_t_pending_records=()
          local -A z_t_current_idx=(describe 1 context 2 it 0)
          local -A z_t_states=(skip_describe false skip_context false skip_it false compact false tests 0 pendings 0)

          z.t.xit "example"

          print -r -- "$z_t_logs[3]"
          print -r -- "$z_t_current_idx[it] $z_t_states[tests] $z_t_states[pendings] $z_t_states[skip_it]"
          print -r -- "$z_t_pending_records"
        }
      )

      z.t.expect "$observed" $'\033[33m      example\033[0m\n3 1 1 true\n1:2:3'
    }
  }
}
