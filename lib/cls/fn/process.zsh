# z.cls.fnで収集しているメソッド本体を終了する。
# このマーカーの実行前に、DEBUGトラップが本体を登録する。
#
# REPLY: null
# return: 0|1
#
# example:
#  # 前提: Counterを定義中で、属性countを登録している
#  z.cls.fn increment
#    (( ++count ))
#  z.cls.fn.done
#  # return: 0
#  # 変更後: incrementの本体を登録し、収集を終了
z.cls.fn.done() {
  local result=${z_cls_capture_done_result:-0}

  unset z_cls_capture_done_result

  return $result
}
