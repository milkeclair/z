z_t_states[file_path]=$1

# テストファイルのパスを取得する
#
# REPLY: ファイルのパス
# return: null
#
# example:
#  z_t_states[file_path]="/tmp/example_test.zsh"
#  z.t._state.file_path
#  # REPLY: "/tmp/example_test.zsh"
z.t._state.file_path() {
  REPLY=${z_t_states[file_path]}
}
