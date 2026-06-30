# generate a job id
# timestamp.pid.random
#
# REPLY: job id
# return: null
#
# example:
#  z.job.id._generate
z.job.id._generate() {
  local timestamp=$(date +%Y%m%dT%H%M%S%N)
  z.return "$timestamp.$$.$RANDOM"
}
