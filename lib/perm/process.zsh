# パスの権限と所有者を変更する
# 権限名はread・write・execute・noneをカンマで区切り、mode指定時はmodeを優先する
#
# $path: 対象のパス
# $owner?: 所有者名またはID
# $group?: グループ名またはID
# $mode?: chmodの権限モード
# $mode_owner?: カンマ区切りの所有者の権限
# $mode_group?: カンマ区切りのグループ権限
# $mode_other?: カンマ区切りのその他ユーザーの権限
# REPLY: null
# return: 変更できた場合、または変更指定がない場合は0、それ以外は1
#
# example:
#  # 対象ファイルが存在し、権限を変更できる場合
#  z.perm path=/tmp/z-example.txt mode=600
#  # return: 0
#  # 変更後のモード: 600
#
#  # 所有者へ読み書き、グループへ読み取りを許可する場合
#  z.perm \
#    path=/tmp/z-example.txt \
#    mode_owner=read,write,none \
#    mode_group=read,none,none \
#    mode_other=none,none,none
#  # return: 0
#  # 変更後のモード: 640
#
#  # exampleユーザーとstaffグループが存在し、所有者を変更できる場合
#  z.perm path=/tmp/z-example.txt owner=example group=staff
#  # return: 0
#  # 変更後: 所有者はexample、グループはstaff
z.perm() {
  z.perm._apply recursive=false "$@" # zls: ignore
}

# ディレクトリの権限と所有者を再帰的に変更する
# 権限名はread・write・execute・noneをカンマで区切り、mode指定時はmodeを優先する
#
# $path: 対象ディレクトリのパス
# $owner?: 所有者名またはID
# $group?: グループ名またはID
# $mode?: chmodの権限モード
# $mode_owner?: カンマ区切りの所有者の権限
# $mode_group?: カンマ区切りのグループ権限
# $mode_other?: カンマ区切りのその他ユーザーの権限
# REPLY: null
# return: 変更できた場合、または変更指定がない場合は0、それ以外は1
#
# example:
#  # 対象ディレクトリと配下の権限を変更できる場合
#  z.perm.dir path=/tmp/z-example mode=755
#  # return: 0
#  # 変更後のモード: 対象ディレクトリと配下すべてが755
#
#  # 所有者へ読み書き実行、グループへ読み取り実行を再帰的に許可する場合
#  z.perm.dir \
#    path=/tmp/z-example \
#    mode_owner=read,write,execute \
#    mode_group=read,none,execute \
#    mode_other=none,none,none
#  # return: 0
#  # 変更後のモード: 対象ディレクトリと配下すべてが750
#
#  # exampleユーザーとstaffグループが存在し、配下の所有者も変更できる場合
#  z.perm.dir path=/tmp/z-example owner=example group=staff
#  # return: 0
#  # 変更後: 対象ディレクトリと配下の所有者はexample、グループはstaff
z.perm.dir() {
  z.perm._apply recursive=true "$@" # zls: ignore
}

# 再帰指定に応じて権限と所有者を変更する
# 権限名はread・write・execute・noneをカンマで区切り、mode指定時はmodeを優先する
#
# $recursive?: 再帰的に変更を適用するか（既定: false）
# $path: 対象のパス
# $owner?: 所有者名またはID
# $group?: グループ名またはID
# $mode?: chmodの権限モード
# $mode_owner?: カンマ区切りの所有者の権限
# $mode_group?: カンマ区切りのグループ権限
# $mode_other?: カンマ区切りのその他ユーザーの権限
# REPLY: null
# return: 変更できた場合、または変更指定がない場合は0、それ以外は1
#
# example:
#  # 対象ファイルが存在し、権限を変更できる場合
#  z.perm._apply recursive=false path=/tmp/z-example.txt mode=600
#  # return: 0
#  # 変更後のモード: 600
#
#  # exampleユーザーとstaffグループが存在し、配下の権限と所有者を変更できる場合
#  z.perm._apply \
#    recursive=true path=/tmp/z-example owner=example group=staff \
#    mode_owner=read,write,execute \
#    mode_group=read,none,execute \
#    mode_other=none,none,none
#  # return: 0
#  # 変更後: 対象ディレクトリと配下はモード750、所有者example、グループstaff
z.perm._apply() {
  z.arg.named recursive $@ default=false && local recursive=$REPLY
  z.arg.named path $@ && local target_path=$REPLY

  if z.is.null "$target_path"; then
    z.io.error "path is required"
    return 1
  fi

  local recursive_opts=()
  z.is.true $recursive && recursive_opts=(-R)

  z.perm._owner_spec "$@"
  local owner_status=$?
  local owner_spec=$REPLY
  if z.int.is.zero $owner_status; then
    chown ${recursive_opts[@]} "$owner_spec" "$target_path" || return 1
  fi

  z.perm._mode "$@"
  local mode_status=$?
  local mode=$REPLY
  if z.int.is.zero $mode_status; then
    chmod ${recursive_opts[@]} "$mode" "$target_path" || return 1
  fi
}

# chown用の所有者指定を組み立てる
#
# $owner?: 所有者名またはID
# $group?: グループ名またはID
# REPLY: chown用の所有者指定
# return: 所有者またはグループの指定がある場合は0、それ以外は1
#
# example:
#  z.perm._owner_spec owner=user group=group
#  # REPLY: "user:group"
#  z.perm._owner_spec owner=user
#  # REPLY: "user"
#  z.perm._owner_spec group=group
#  # REPLY: ":group"
z.perm._owner_spec() {
  z.arg.named owner $@ default="" && local owner=$REPLY
  z.arg.named group $@ default="" && local group=$REPLY

  if z.is.null "$owner" && z.is.null "$group"; then
    REPLY=""
    return 1
  fi

  if z.is.not.null "$owner" && z.is.not.null "$group"; then
    REPLY="$owner:$group"
  elif z.is.not.null "$owner"; then
    REPLY="$owner"
  else
    REPLY=":$group"
  fi
}

# chmodの権限モードを組み立てる
#
# $mode?: chmodの権限モード
# $mode_owner?: カンマ区切りの所有者の権限
# $mode_group?: カンマ区切りのグループ権限
# $mode_other?: カンマ区切りのその他ユーザーの権限
# REPLY: chmodの権限モード
# return: 権限モードを組み立てられた場合は0、それ以外は1
#
# example:
#  z.perm._mode mode=600
#  # REPLY: "600"
#
#  z.perm._mode mode_owner=read,write,none mode_group=read,none,none mode_other=none,none,none
#  # REPLY: "640"
#
#  # modeを指定した場合は、mode_owner等より優先する
#  z.perm._mode mode=600 mode_owner=read,write,execute
#  # REPLY: "600"
z.perm._mode() {
  z.arg.named mode $@ default="" && local mode=$REPLY
  if z.is.not.null "$mode"; then
    REPLY="$mode"
    return 0
  fi

  local has_mode_parts=false
  for arg in "$@"; do
    z.str.start_with "$arg" "mode_owner=" && has_mode_parts=true
    z.str.start_with "$arg" "mode_group=" && has_mode_parts=true
    z.str.start_with "$arg" "mode_other=" && has_mode_parts=true
  done

  if z.is.false $has_mode_parts; then
    REPLY=""
    return 1
  fi

  z.arg.named mode_owner $@ default="none,none,none" && local mode_owner=$REPLY
  z.arg.named mode_group $@ default="none,none,none" && local mode_group=$REPLY
  z.arg.named mode_other $@ default="none,none,none" && local mode_other=$REPLY

  z.perm._mode_digit "$mode_owner" || return 1
  local owner_digit=$REPLY
  z.perm._mode_digit "$mode_group" || return 1
  local group_digit=$REPLY
  z.perm._mode_digit "$mode_other" || return 1
  local other_digit=$REPLY

  REPLY="${owner_digit}${group_digit}${other_digit}"
}

# 権限名をchmodの権限値1桁へ変換する
#
# $1: カンマ区切りの権限
# REPLY: chmodの権限値1桁
# return: 権限の指定が正しい場合は0、それ以外は1
#
# example:
#  z.perm._mode_digit read,write,none
#  # REPLY: 6
#  z.perm._mode_digit read,write,execute
#  # REPLY: 7
z.perm._mode_digit() {
  local mode_values=$1
  local digit=0

  z.str.split str="$mode_values" delimiter=","
  local permissions=($REPLY)

  for permission in $permissions; do
    case $permission in
    read)
      ((digit += 4))
      ;;
    write)
      ((digit += 2))
      ;;
    execute)
      ((digit += 1))
      ;;
    none|"")
      ;;
    *)
      z.io.error "invalid permission: $permission"
      return 1
      ;;
    esac
  done

  REPLY=$digit
}
