for dsl_file in ${z_root}/lib/t/dsl/*.zsh; do
  source ${dsl_file} $1
done

z.eq $z_mode "test" && {
  trap "z.t.teardown" EXIT

  z.t._state.fn_originals.save

  command_not_found_handler() {
    local cmd=$1
    z.t._mark_not_found_error "message=command not found: $cmd"
    return 127
  }
}

# mark the test suite as having command not found error
#
# $message: error message
# REPLY: null
# return: 127(command not found)
#
# example:
#  z.t.mark_not_found_error message="command not found: ls"
z.t._mark_not_found_error() {
  z.arg.named message $@ && local message=$REPLY

  local error_flag_file="/tmp/z_t_error_$$"
  z.file.make.with_dir path=$error_flag_file
  echo $message >> $error_flag_file

  return 127
}
