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

### Library

This library provides a set of utility functions for common tasks.

Functions are namespaced with `z.` prefix.
And modules are namespaced with `z.<module>.` prefix.

The following rules apply under lib.

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

### Testing

This library provides a testing framework for writing and running tests.
Tests are written in zsh and use a RSpec-like syntax.

Run `z.t` to run all tests.
z.t accepts the following options.

- `-l`
  - Display test details.
- `-f`
  - Display only failed tests.

Tests are placed in the `test` directory.
Tests are namespaced with `z.t.` prefix.
And modules are namespaced with `z.t.<module>.` prefix.

The following rules apply under test.

- describe
  - Describe the function or feature being tested.
- xdescribe
  - Skip the describe block.
- context
  - Describe the context in which the tests are run.
- xcontext
  - Skip the context block.
- it
  - Describe the expected behavior of the function or feature.
- xit
  - Skip the it block.
- expect
  - Assert the expected behavior of the function or feature.
  - The expectation functions are namespaced with `z.t.expect.` prefix.
- mock
  - Mock a function or command.
  - The mock is automatically restored after the test and assertion.
  - If you want to skip restoring in assertion, use `skip_unmock` option.
  - The mock result is placed in `REPLY`, not `return`.
  - Modes:
    - Default mode: Records function calls without executing original behavior.
    - `call_original` mode: Executes original function after recording the call.
      - `z.t.mock.call_original` function: Same as `call_original` mode.
    - Provide custom behavior: You can provide custom behavior by passing a command as the second argument.

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
z.t.describe "my.argument_check"; {
  z.t.context "when more than 2 args"; {
    z.t.it "prints 'more than 2 args'"; {
      z.t.mock.call_original "z.io"

      local output=$(my.argument_check "1" "2" "3")

      z.t.mock.result
      z.t.expect.reply.include "more than 2 args"
      z.t.expect.include $output "more than 2 args"
    }
  }

  z.t.context "when 2 or less args"; {
    z.t.it "prints '2 or less args' to stderr"; {
      z.t.mock "z.int.gt" "return 1"
      z.t.mock "z.io"
      z.t.mock "z.io.error"

      my.argument_check "1" "2" "3"

      z.t.mock.result "z.io"
      z.t.expect.reply.null "skip_unmock"

      z.t.mock.result "z.io.error"
      z.t.expect.reply.include "2 or less args"
    }
  }
}
```

## Debug

This library provides a debug function for interactive debugging.

### Using the Debug Function

Call `z.debug` in your script to enter debug mode. When debug mode is enabled, the function will pause execution and provide an interactive prompt.

To enable debug mode, use the `z.debug.enable` function.
To disable debug mode, use the `z.debug.disable` function.

Available commands in debug mode:

- `c` or `continue`: Continue execution.
- `p <var>` or `print <var>`: Print the value of a variable.
- `h` or `help`: Show help.
- `q` or `quit` or `exit`: Exit the script.

Example:

```zsh
my.function() {
  local var="hello"
  z.debug
  z.io $var
}
```

## Language Server

This library provides a language server.

Download: https://marketplace.visualstudio.com/items?itemName=milkeclair.z-ls

### Features

- Autocompletion
  - Function names
- Hover information
  - name
  - description
  - parameters
  - returns
  - example
- Go to definition
- Diagnostics
  - Function not found
  - Empty line
