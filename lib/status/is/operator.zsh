# 終了コードを比較する
#
# REPLY: null
# return: 0|1
#
# example:
#  true
#  z.status.is.true
#  # return: 0
#  false
#  z.status.is.true
#  # return: 1
z.status.is.true() {
  z.status
  z.is.true $REPLY
}

# 終了コードを比較する
#
# REPLY: null
# return: 0|1
#
# example:
#  false
#  z.status.is.false
#  # return: 0
#  true
#  z.status.is.false
#  # return: 1
z.status.is.false() {
  z.status
  z.is.false $REPLY
}
