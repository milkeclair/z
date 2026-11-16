# git addを実行する
# ファイルを明示的に指定するよう、"git add ."を禁止する
#
# $@: ファイル
# REPLY: null
# return: null
#
# example:
#  # 2つのファイルが作業ツリーに存在する場合
#  z.git.add file1.txt file2.txt
#  # 結果: file1.txtとfile2.txtがステージされる
z.git.add() {
  if z.is.eq $1 "."; then
    z.io 'Rejecting "git add ." command. Please specify the files to add explicitly.'
    return 1
  fi

  git add "$@"
}
