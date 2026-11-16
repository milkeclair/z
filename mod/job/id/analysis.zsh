# ジョブIDを生成する
# timestamp.pid.random
#
# REPLY: ジョブID
# return: null
#
# example:
#  z.job.id._generate
z.job.id._generate() {
  local timestamp=$(date +%Y%m%dT%H%M%S%N)
  REPLY="$timestamp.$$.$RANDOM"
}
