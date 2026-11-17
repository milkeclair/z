# 引数位置で登録済みのプロジェクト名を補完する
#
# REPLY: null
# return: 0|1
#
# example:
#  # 補完コンテキストでz.pj alpを入力し、alpha・alpineを登録済みの場合
#  z.pj.completion._run
#  # 補完候補: alpha、alpine
z.pj.completion._run() {
  if z.int.is.eq $CURRENT 2; then
    z.pj.file._names && local names=("${REPLY[@]}")
    _describe -t projects "projects" names -l && return
  fi

  z.completion.complete._docs
}
