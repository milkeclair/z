source "$z_main"

z.t.describe "z.t.context"; {
  z.t.context "親スイートのskip状態が異なる場合"; {
    z.t.it "見出しの色と子階層のskip状態を親に合わせる"; {
      for suite_skip in false true; do
        local observed=$(
          () {
            local -a z_t_logs=(suite)
            local -A z_t_current_idx=(describe 1 context 8 it 7)
            local -A z_t_states=(skip_describe "$suite_skip" skip_context true skip_it true)

            z.t.context "context"

            print -r -- "$z_t_logs[2]"
            print -r -- "$z_t_current_idx[describe] $z_t_current_idx[context] $z_t_current_idx[it]"
            print -r -- "$z_t_states[skip_describe] $z_t_states[skip_context] $z_t_states[skip_it]"
          }
        )

        if [[ "$suite_skip" == true ]]; then
          z.t.expect "$observed" $'\033[33m    context\033[0m\n1 2 0\ntrue true true'
        else
          z.t.expect "$observed" $'\033[32m    context\033[0m\n1 2 0\nfalse false false'
        fi
      done
    }
  }
}

z.t.describe "z.t.xcontext"; {
  z.t.context "コンテキストをpendingにする場合"; {
    z.t.it "黄色の見出しを追加しスイート以外をskipする"; {
      local observed=$(
        () {
          local -a z_t_logs=(suite)
          local -A z_t_current_idx=(describe 1 context 8 it 7)
          local -A z_t_states=(skip_describe false skip_context false skip_it false)

          z.t.xcontext "context"

          print -r -- "$z_t_logs[2]"
          print -r -- "$z_t_current_idx[describe] $z_t_current_idx[context] $z_t_current_idx[it]"
          print -r -- "$z_t_states[skip_describe] $z_t_states[skip_context] $z_t_states[skip_it]"
        }
      )

      z.t.expect "$observed" $'\033[33m    context\033[0m\n1 2 0\nfalse true true'
    }
  }
}
