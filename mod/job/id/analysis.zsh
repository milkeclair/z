# ジョブIDを生成する
# timestamp.pid.random
#
# REPLY: ジョブID
# return: null
#
# example:
#  z.job.id._generate
#  # REPLYの例: "20260623T121530000000000.100.1"
#  # 日時・シェルPID・乱数によって値は変わる
z.job.id._generate() {
  local timestamp=$(date +%Y%m%dT%H%M%S%N)
  REPLY="$timestamp.$$.$RANDOM"
}
