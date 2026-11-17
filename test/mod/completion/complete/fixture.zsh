# 補完候補として使う最初の関数
z.fixture.alpha() {
  :
}

# 補完候補として使う2つ目の関数
z.fixture.beta() {
  :
}

# 位置指定のcode引数を持つ補完対象
#
# $1 [code]: コード文字列
# REPLY: null
# return: 0
z.code_fixture() {
  : "$1"
}
