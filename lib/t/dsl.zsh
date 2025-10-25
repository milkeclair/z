for dsl_file in ${z_root}/lib/t/dsl/*.zsh; do
  source ${dsl_file} $1
done

z.eq $z_mode "test" && {
  trap "z.t.teardown" EXIT

  command_not_found_handler() {
    local cmd=$1
    z.t._mark_not_found_error "command not found: $cmd"
    return 127
  }
}

# mark the test suite as having command not found error
#
# $1: error message
# REPLY: null
# return: 127(command not found)
#
# example:
#  z.t.mark_not_found_error "command not found: ls"
z.t._mark_not_found_error() {
  local message=$1

  local error_flag_file="/tmp/z_t_error_$$"
  z.file.make_with_dir $error_flag_file
  echo $message >> $error_flag_file

  return 127
}
