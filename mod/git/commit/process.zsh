# git commit alias
#
# $1: commit tag
# $2: commit message
# $3?: ticket number
# $@: commit options (e.g. -nt, -ca, -ae)
# REPLY: null
# return: null
#
# example:
#   z.git.c feat "add new feature" TICKET-123 -ca
z.git.c() {
  z.git.commit "$@" # zls: ignore
}

# tdd commit alias for red cycle
#
# $1: commit tag
# $2: commit message
# $3?: ticket number
# $@: commit options (e.g. -nt, -ca, -ae)
# REPLY: null
# return: null
#
# example:
#   z.git.c.r feat "add new feature" TICKET-123 -ca -ae
z.git.c.r() {
  z.git.commit.tdd red "$@" # zls: ignore
}

# tdd commit alias for green cycle
#
# $1: commit tag
# $2: commit message
# $3?: ticket number
# $@: commit options (e.g. -nt, -ca, -ae)
# REPLY: null
# return: null
#
# example:
#   z.git.c.g feat "add new feature" TICKET-123 -ca -ae
z.git.c.g() {
  z.git.commit.tdd green "$@" # zls: ignore
}

# git commit
#
# $1: commit tag
# $2: commit message
# $3?: ticket number
# $@: commit options (e.g. -nt, -ca, -ae)
#
# REPLY: null
# return: null
#
# example:
#   z.git.commit feat "add new feature" TICKET-123 -ca
z.git.commit() {
  z.git.commit.arg.is.enough $@ || return 1

  z.group "extract arguments"; {
    z.git.commit.arg.extract $@
    local -A args=(${(@)REPLY})
    local tag=$args[tag] && local message=$args[message] && local ticket=$args[ticket]

    z.git.commit.arg.extract.opts ${(@kv)args}
    local opts=(${(@)REPLY})
  }

  z.git.commit.tag.is.valid $tag || return 1

  if z.is.null $ticket && z.git.commit.arg.is.not.no_ticket ${opts[@]}; then
    z.git.hp.ticket && ticket=$REPLY
  fi

  z.git.commit.msg.build tag=$tag message=$message ticket=$ticket
  z.git.commit.with_committer $REPLY ${opts[@]}
}

# tdd commit
#
# $1: commit cycle (red, green)
# $2: commit tag
# $3: commit message
# $4?: ticket number (optional)
# $@: commit options (e.g. -nt, -ca, -ae)
#
# REPLY: null
# return: null
#
# example:
#   z.git.commit.tdd red feat "add new feature" TICKET-123 -ca -ae
z.git.commit.tdd() {
  local cycle=$1 && shift

  z.git.commit.tdd.cycle.is.valid $cycle || return 1
  z.git.commit.arg.is.enough $@ || return 1

  z.group "extract arguments"; {
    z.git.commit.arg.extract $@
    local -A args=(${(@)REPLY})
    local tag=$args[tag] && local message=$args[message] && local ticket=$args[ticket]

    z.git.commit.arg.extract.opts ${(@kv)args}
    local opts=(${(@)REPLY})
  }

  z.git.commit.tag.is.valid $tag || return 1

  if z.is.null $ticket && z.git.commit.arg.is.not.no_ticket ${opts[@]}; then
    z.git.hp.ticket && ticket=$REPLY
  fi

  z.git.commit.msg.build tag=$tag message=$message ticket=$ticket cycle=$cycle
  z.git.commit.with_committer $REPLY ${opts[@]}
}

# commit with committer info
#
# $1: commit message
# $@: commit options (e.g. -nt, -ca, -ae)
#
# REPLY: null
# return: null
#
# example:
#   z.git.commit.with_committer "feat: add new feature" -ca
z.git.commit.with_committer() {
  local message=$1 && shift

  z.git.commit.opts.extract $@
  local opts=(${(@)REPLY})

  command git commit -m $message ${opts[@]}
  z.git.commit.help.committer
}

# show help for git commit
#
# REPLY: null
# return: null
#
# example:
#   z.git.commit.help
z.git.commit.help() {
  z.git.commit.tag.list && local tags=$REPLY

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
