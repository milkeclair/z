# z.cls.methodで収集しているメソッド本体を終了する。
# DEBUGトラップが本体を登録し、失敗した場合は1を返す。
#
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.draw Counter
#    z.cls.method value
#      REPLY=ready
#    z.cls.method.defined
#    # return: 0
#  z.cls.drew
z.cls.method.defined() {
  {
    return ${z_cls_capture_done_result:-0}
  } always {
    unset z_cls_capture_done_result
  }
}
