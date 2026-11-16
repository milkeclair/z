z_t_states[file_path]=$1

# テストファイルのパスを取得する
#
# REPLY: null
# return: ファイルのパス
#
# example:
#  z.t._state.file_path  #=> "/path/to/test_file.zsh"
z.t._state.file_path() {
  REPLY=${z_t_states[file_path]}
}
