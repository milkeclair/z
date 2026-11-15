# load completion cache from a job result file
#
# $result: result file path
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.cache.load._result result=/tmp/z/job/result
z.completion.cache.load._result() {
  z.arg.named result "$@" && local result=$REPLY
  z.is.null "$result" && return 1

  source "$result"
  z.completion.compdef._register
}
