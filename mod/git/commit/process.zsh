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

  z.git.commit.msg.build tag=$tag "message=$message" ticket=$ticket
  z.git.commit.with_committer "$REPLY" ${opts[@]}
}

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

  z.git.commit.msg.build tag=$tag "message=$message" ticket=$ticket cycle=$cycle
  z.git.commit.with_committer "$REPLY" ${opts[@]}
}

z.git.commit.with_committer() {
  local message=$1 && shift

  z.git.commit.opts.extract $@
  local opts=(${(@)REPLY})

  command git commit -m "$message" ${opts[@]}
  z.git.commit.help.committer
}

z.git.commit.help() {
  z.git.commit.tag.list && local tags=$REPLY

  z.io.empty
  z.io indent=1 "Usage:"
  z.io indent=2 "commit:   git c [tag] message ?[ticket] ?[-nt|-ca|-ae]"
  z.io indent=2 "red:      git red [tag] message ?[ticket] ?[-nt|-ca|-ae]"
  z.io indent=2 "green:    git green [tag] message ?[ticket] ?[-nt|-ca|-ae]"
  z.io indent=2 "refactor: git green refactor message ?[ticket] ?[-nt|-ca|-ae]"
  z.io.line
  z.io indent=1 "Valid tags are:"
  z.io indent=2 "${tags[*]}"
  z.io.line
  z.io indent=1 "Options:"
  z.io indent=2 "-nt: no ticket"
  z.io indent=2 "-ca: amend"
  z.io indent=2 "-ae: allow empty"
}
