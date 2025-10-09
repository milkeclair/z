source ${z_main}

my.argument_check() {
  z.arr.count $@
  if z.int.gt $REPLY 2; then
    z.io "more than 2 args"
  else
    z.io.error "2 or less args"
  fi
}

z.t.describe "my.argument_check"; {
  z.t.context "when more than 2 args"; {
    z.t.it "prints 'more than 2 args'"; {
      z.t.mock "z.io"

      my.argument_check "1" "2" "3"

      z.t.mock.result
      z.t.expect.reply.include "more than 2 args"
    }
  }

  z.t.context "when 2 or less args"; {
    z.t.it "prints '2 or less args' to stderr"; {
      z.t.mock "z.io"
      z.t.mock "z.io.error"

      my.argument_check "1" "2"

      z.t.mock.result "z.io"
      z.t.expect.reply.null "skip_unmock"

      z.t.mock.result "z.io.error"
      z.t.expect.reply.include "2 or less args"
    }
  }
}
