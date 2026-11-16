# 現在のシェルで補完を利用できるか確認する
#
# REPLY: null
# return: 0|1
#
# example:
#  # -cを指定していない対話シェルで実行した場合
#  z.completion.is._interactive
#  # return: 0
#  # zsh -cの中で実行した場合
#  # return: 1
z.completion.is._interactive() {
  z.is.eq "$options[interactive]" on &&
    ! z.var.exists ZSH_EXECUTION_STRING
}
