# get a port env value
#
# $1: configuration key
# REPLY: environment value
# return: null
#
# example:
#  z.wt_proxy._port.public.env public_port_1
z.wt_proxy._port.public.env() {
  local key=$1

  z.wt_proxy._port.public.env.key $key
  z.var.get $REPLY
}
