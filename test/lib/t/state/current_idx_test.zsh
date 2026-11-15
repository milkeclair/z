source "$z_main"

z.t.describe "z.t._state.current_idx.add"; {
  z.t.context "各階層に見出しを追加する場合"; {
    z.t.it "現在の見出し位置と子階層を更新する"; {
      for index_context in describe context it other; do
        local observed=$(
          () {
            local -a z_t_logs=(first second)
            local -A z_t_current_idx=(describe 7 context 8 it 9)

            z.t._state.current_idx.add "$index_context"

            print -r -- "$REPLY $z_t_current_idx[describe] $z_t_current_idx[context] $z_t_current_idx[it]"
          }
        )

        case "$index_context" in
        describe) z.t.expect "$observed" "2 2 0 0" ;;
        context) z.t.expect "$observed" "2 7 2 0" ;;
        it) z.t.expect "$observed" "2 7 8 2" ;;
        other) z.t.expect "$observed" "2 7 8 9" ;;
        esac
      done
    }
  }

  z.t.context "空のlogが含まれる場合"; {
    z.t.it "従来と同じ件数を返す"; {
      local observed=$(
        () {
          local -a z_t_logs=(first "" third)
          local -A z_t_current_idx=(describe 0 context 0 it 0)

          z.t._state.current_idx.add it

          print -r -- "$REPLY $z_t_current_idx[it]"
        }
      )

      z.t.expect "$observed" "2 2"
    }
  }

  z.t.context "logがない場合"; {
    z.t.it "0を返す"; {
      local observed=$(
        () {
          local -a z_t_logs=()
          local -A z_t_current_idx=(describe 0 context 0 it 9)

          z.t._state.current_idx.add it

          print -r -- "$REPLY $z_t_current_idx[it]"
        }
      )

      z.t.expect "$observed" "0 0"
    }
  }
}
