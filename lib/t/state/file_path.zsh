z_t_states[file_path]=$1

# get the test file path
#
# REPLY: null
# return: file path
#
# example:
#  z.t._state.file_path  #=> "/path/to/test_file.zsh"
z.t._state.file_path() {
  z.return ${z_t_states[file_path]}
}
