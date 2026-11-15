source "$z_main"

z.t.describe "z.t.describe"; {
  z.t.context "前のスイートがpendingの場合"; {
    z.t.it "緑の見出しを追加しskip状態をリセットする"; {
      local observed=$(
        () {
          local -a z_t_logs=()
          local -A z_t_current_idx=(describe 9 context 8 it 7)
          local -A z_t_states=(skip_describe true skip_context true skip_it true)

          z.t.describe $'\033[31msuite\033[0m'

          print -r -- "$z_t_logs[1]"
          print -r -- "$z_t_current_idx[describe] $z_t_current_idx[context] $z_t_current_idx[it]"
          print -r -- "$z_t_states[skip_describe] $z_t_states[skip_context] $z_t_states[skip_it]"
        }
      )

      z.t.expect "$observed" $'\033[32m  suite\033[0m\n1 0 0\nfalse false false'
    }
  }
}

z.t.describe "z.t.xdescribe"; {
  z.t.context "スイートをpendingにする場合"; {
    z.t.it "黄色の見出しを追加し全階層をskipする"; {
      local observed=$(
        () {
          local -a z_t_logs=()
          local -A z_t_current_idx=(describe 9 context 8 it 7)
          local -A z_t_states=(skip_describe false skip_context false skip_it false)

          z.t.xdescribe "suite"

          print -r -- "$z_t_logs[1]"
          print -r -- "$z_t_current_idx[describe] $z_t_current_idx[context] $z_t_current_idx[it]"
          print -r -- "$z_t_states[skip_describe] $z_t_states[skip_context] $z_t_states[skip_it]"
        }
      )

      z.t.expect "$observed" $'\033[33m  suite\033[0m\n1 0 0\ntrue true true'
    }
  }
}
