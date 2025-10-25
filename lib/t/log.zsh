for log_file in ${z_root}/lib/t/log/*.zsh; do
  source ${log_file} $1
done

# Logging functions for test framework
#
# REPLY: null
# return: null
#
# example:
#  z.t._log
z.t._log() {
  z.t._state.logs
}
