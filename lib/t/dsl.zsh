z.eq $z_mode "test" && {
  trap "z.t.teardown" EXIT
}

z.t.describe() {
  local description=$1

  z.str.indent 1 $description
  z.str.color.green $REPLY

  z.t.state.logs.add $REPLY
  z.t.state.current_idx.add "describe"
}

z.t.xdescribe() {
  local description=$1

  z.str.indent 1 $description
  z.str.color.yellow $REPLY

  z.t.state.logs.add $REPLY
  z.t.state.current_idx.add "describe"
}

z.t.context() {
  local context=$1

  z.str.indent 2 $context
  z.str.color.green $REPLY

  z.t.state.logs.add $REPLY
  z.t.state.current_idx.add "context"
}

z.t.xcontext() {
  local context=$1

  z.str.indent 2 $context
  z.str.color.yellow $REPLY

  z.t.state.logs.add $REPLY
  z.t.state.current_idx.add "context"
}

z.t.it() {
  REPLY=""

  local it=$1

  z.str.indent 3 $it
  z.str.color.green $REPLY

  z.t.state.logs.add $REPLY
  z.t.state.current_idx.add "it"
  z.t.state.tests.increment
}

z.t.xit() {
  REPLY=""

  local it=$1

  z.str.indent 3 $it
  z.str.color.yellow $REPLY

  z.t.state.logs.add $REPLY
  z.t.state.current_idx.add "it"
  z.t.state.tests.increment
}

z.t.teardown() {
  z.t.mock.unmock.all
  z.t.remove_tmp_dir
  z.t.log.show
}
