# z

A zsh utility library for me who can't memorize shell script syntax.
Provide functions with readable names for syntax that is not intuitive for me.

## Installation

### First time
`curl -sL https://raw.githubusercontent.com/milkeclair/z/main/install.zsh | zsh`

### Reinstall or Update
`z.install`

### Uninstall
`z.uninstall`

## Usage

Functions are namespaced with `z.` prefix.
And modules are namespaced with `z.<module>.` prefix.

The following rules apply under Lib.

- analysis
  - Analyze without modifying the data.
  - The return value is placed in `REPLY`, not `return`.
- operator
  - Check arguments and `return` true or false.
  - The return value is placed in the return value, not `REPLY`.
  - It can be used in if statements.
- process
  - Modify the data.
  - The return value is placed in `REPLY`, not `return`.

### Examples

Script to check if the number of arguments is more than 2.

```zsh
my.argument_check() {
  z.arr.count $@
  if z.int.gt $REPLY 2; then
    z.io "more than 2 args"
  else
    z.io.error "2 or less args"
  fi
}
```

Test
```zsh
source ${z_main}

z.t.describe "my.argument_check"; {
  z.t.context "when more than 2 args"; {
    z.t.it "prints 'more than 2 args'"; {
      local out=$(my.argument_check "1" "2" "3")

      z.t.expect_include $out "more than 2 args"
    }
  }

  z.t.context "when 2 or less args"; {
    z.t.it "prints '2 or less args' to stderr"; {
      local out=$(my.argument_check "1" "2" 2> /dev/null)
      local err=$(my.argument_check "1" "2" 2>&1 1> /dev/null)

      z.t.expect $out ""
      z.t.expect_include $err "2 or less args"
    }
  }
}
```
