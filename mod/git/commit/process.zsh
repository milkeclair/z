# git commitの別名
#
# $1: コミットタグ
# $2: コミットメッセージ
# $3?: チケット番号
# $@: コミットオプション（例: -nt、-ca、-ae）
# REPLY: null
# return: null
#
# example:
#  # コミット可能な変更がある場合
#  z.git.c feat "add new feature" TICKET-123
#  # 新しいコミットのメッセージ: "feat: #TICKET-123 add new feature"
z.git.c() {
  z.git.commit "$@" # zls: ignore
}

# TDDのredサイクル用コミットの別名
#
# $1: コミットタグ
# $2: コミットメッセージ
# $3?: チケット番号
# $@: コミットオプション（例: -nt、-ca、-ae）
# REPLY: null
# return: null
#
# example:
#  # 空コミットを許可する場合
#  z.git.c.r test "add failing test" TICKET-123 -ae
#  # 新しいコミットのメッセージ: "test: #TICKET-123 [red] add failing test"
z.git.c.r() {
  z.git.commit.tdd red "$@" # zls: ignore
}

# TDDのgreenサイクル用コミットの別名
#
# $1: コミットタグ
# $2: コミットメッセージ
# $3?: チケット番号
# $@: コミットオプション（例: -nt、-ca、-ae）
# REPLY: null
# return: null
#
# example:
#  # 空コミットを許可する場合
#  z.git.c.g test "make test pass" TICKET-123 -ae
#  # 新しいコミットのメッセージ: "test: #TICKET-123 [green] make test pass"
z.git.c.g() {
  z.git.commit.tdd green "$@" # zls: ignore
}

# git commitを実行する
#
# $1: コミットタグ
# $2: コミットメッセージ
# $3?: チケット番号
# $@: コミットオプション（例: -nt、-ca、-ae）
#
# REPLY: null
# return: null
#
# example:
#  # コミット可能な変更がある場合
#  z.git.commit feat "add new feature" TICKET-123
#  # 新しいコミットのメッセージ: "feat: #TICKET-123 add new feature"
z.git.commit() {
  z.git.commit._arg.is.enough $@ || return 1

  z.group "extract arguments"; {
    z.git.commit._arg.extract $@
    local -A args=("${(@)REPLY}")
    local tag=$args[tag] && local message=$args[message] && local ticket=$args[ticket]

    z.git.commit._arg.extract.opts "${(@kv)args}"
    local opts=(${(@)REPLY})
  }

  z.git.commit._tag.is.valid $tag || return 1

  if z.is.null $ticket && z.git.commit._arg.is.not.no_ticket ${opts[@]}; then
    z.git._hp.ticket && ticket=$REPLY
  fi

  z.git.commit._msg.build tag=$tag message=$message ticket=$ticket
  z.git.commit._with_committer "$REPLY" ${opts[@]}
}

# TDDのコミット
#
# $1: コミットサイクル（red、green）
# $2: コミットタグ
# $3: コミットメッセージ
# $4?: チケット番号（任意）
# $@: コミットオプション（例: -nt、-ca、-ae）
#
# REPLY: null
# return: null
#
# example:
#  # 空コミットを許可する場合
#  z.git.commit.tdd red test "add failing test" TICKET-123 -ae
#  # 新しいコミットのメッセージ: "test: #TICKET-123 [red] add failing test"
z.git.commit.tdd() {
  local cycle=$1 && shift

  z.git.commit.tdd._cycle.is.valid $cycle || return 1
  z.git.commit._arg.is.enough $@ || return 1

  z.group "extract arguments"; {
    z.git.commit._arg.extract $@
    local -A args=("${(@)REPLY}")
    local tag=$args[tag] && local message=$args[message] && local ticket=$args[ticket]

    z.git.commit._arg.extract.opts "${(@kv)args}"
    local opts=(${(@)REPLY})
  }

  z.git.commit._tag.is.valid $tag || return 1

  if z.is.null $ticket && z.git.commit._arg.is.not.no_ticket ${opts[@]}; then
    z.git._hp.ticket && ticket=$REPLY
  fi

  z.git.commit._msg.build tag=$tag message=$message ticket=$ticket cycle=$cycle
  z.git.commit._with_committer "$REPLY" ${opts[@]}
}

# コミッター情報を指定してコミットする
#
# $1: コミットメッセージ
# $@: コミットオプション（例: -nt、-ca、-ae）
#
# REPLY: null
# return: null
#
# example:
#  # コミット可能な変更がある場合
#  z.git.commit._with_committer "feat: add new feature"
#  # 新しいコミットのメッセージ: "feat: add new feature"
z.git.commit._with_committer() {
  local message=$1 && shift

  z.git.commit._opts.extract $@
  local opts=(${(@)REPLY})

  git commit -m $message ${opts[@]}
  z.git.commit.help._committer
}

# git commitのヘルプを表示する
#
# REPLY: null
# return: null
#
# example:
#  z.git.commit.help
#  # 表示例（一部）: commit:   z.git.c [tag] message ?[ticket] ?[-nt|-ca|-ae]
z.git.commit.help() {
  z.git.commit._tag.list && local tags=$REPLY

  z.io.empty
  z.io indent=1 "Usage:"
  z.io indent=2 "commit:   z.git.c [tag] message ?[ticket] ?[-nt|-ca|-ae]"
  z.io indent=2 "red:      z.git.c.r [tag] message ?[ticket] ?[-nt|-ca|-ae]"
  z.io indent=2 "green:    z.git.c.g [tag] message ?[ticket] ?[-nt|-ca|-ae]"
  z.io.line
  z.io indent=1 "Valid tags:"
  z.io indent=2 "${tags[*]}"
  z.io.line
  z.io indent=1 "Options:"
  z.io indent=2 "-nt: no ticket"
  z.io indent=2 "-ca: amend"
  z.io indent=2 "-ae: allow empty"
}
