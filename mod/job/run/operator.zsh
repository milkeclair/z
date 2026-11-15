# validate job run arguments
#
# $name: job name
# $command: child function name
# $on_success?: parent success callback function name
# $on_failure?: parent failure callback function name
# REPLY: null
# return: 0|1
#
# example:
#  z.job.run._validate name=example command=z.example.build
z.job.run._validate() {
  z.arg.named name "$@" && local name=$REPLY
  z.arg.named command "$@" && local command=$REPLY
  z.arg.named on_success "$@" && local on_success=$REPLY
  z.arg.named on_failure "$@" && local on_failure=$REPLY

  z.is.null "$name" && return 1
  z.is.null "$command" && return 1
  z.int.is.zero ${+functions[$command]} && return 1
  z.is.not.null "$on_success" && z.int.is.zero ${+functions[$on_success]} && return 1
  z.is.not.null "$on_failure" && z.int.is.zero ${+functions[$on_failure]} && return 1

  return 0
}
