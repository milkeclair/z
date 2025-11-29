source ${z_main}

my.argument_check() {
  z.arg.named max $@ default=2 && local max=$REPLY
  z.arg.named.shift max $@
  z.arr.count $REPLY

  if z.int.gt $REPLY $max; then
    z.io "more than $max args"
  else
    z.io.error "$max or less args"
  fi
}

z.t.describe "my.argument_check"; {
  z.t.context "when more than max args"; {
    z.t.it "prints 'more than max args'"; {
      z.t.mock.call_original name="z.io"

      z.io.null my.argument_check max=3 "1" "2" "3" "4"

      z.t.mock.result
      z.t.expect.reply.include "more than 3 args"
    }
  }

  z.t.context "when 2 or less args"; {
    z.t.it "prints '2 or less args' to stderr"; {
      z.t.mock name="z.int.gt" behavior="return 1"
      z.t.mock name="z.io"
      z.t.mock name="z.io.error"

      z.io.null my.argument_check "1" "2" "3"

      z.t.mock.result name="z.io"
      z.t.expect.reply.null skip_unmock=true

      z.t.mock.result name="z.io.error"
      z.t.expect.reply.include "2 or less args"
    }
  }
}
