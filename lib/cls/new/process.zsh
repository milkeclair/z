# インスタンスの作成前に、引数と呼び出し元の代入先変数を検証する。
#
# $1: 公開済みのクラス名
# $2: 宣言済みの書き込み可能なスカラー変数名
# REPLY: null
# return: 0|1
#
# example:
#  z.cls.draw Counter
#  z.cls.drew
#  local -u object=""
#  z.cls.new._validate Counter object
#  # return: 1
#  # 変更後: objectとインスタンスの登録は元のまま
z.cls.new._validate() {
  if z.is.not.eq "$#" 2; then
    z.io.error "Expected a class name and an instance variable name."
    return 1
  fi

  if z.is.null "$1" || ! z.var.exists "z_cls_classes[$1]"; then
    z.io.error "Expected an existing class and an instance variable name."
    return 1
  fi

  if ! z.cls.owner.is._writable "$2"; then
    z.io.error "Instance variable $2 must be a declared writable scalar without a reference."
    return 1
  fi
}
