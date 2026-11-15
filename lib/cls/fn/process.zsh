# End the method block intercepted by z.cls.fn.
# The DEBUG handler registers the body before this marker executes.
#
# REPLY: unchanged
# return: 0|1
#
# example:
#  z.cls.fn.done
z.cls.fn.done() {
  local result=${z_cls_capture_done_result:-0}
  unset z_cls_capture_done_result
  return $result
}
