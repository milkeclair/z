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

### Examples

Script to check if the number of arguments is more than 2.

```zsh
my.argument_check() {
  z.arg.named max default=2 $@ && local max=$REPLY
  z.arg.named.shift max $@
  z.arr.count $REPLY

  if z.int.gt $REPLY $max; then
    z.io "more than $max args"
  else
    z.io.error "$max or less args"
  fi
}
```

Test
```zsh
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
```

### Library

This library provides a set of utility functions for common tasks.

Functions are namespaced with `z.` prefix.
And modules are namespaced with `z.<module>.` prefix.

The following rules apply under lib.

- analysis
  - Analyze without modifying the data.
  - If the function has a return value, it is placed in `REPLY` (not `return`).
- operator
  - Check arguments and `return` true or false.
  - If the function has a return value, it is returned (i.e. placed in the function's return value, not in `REPLY`).
  - It can be used in if statements.
- process
  - Modify the data.
  - If the function has a return value, it is placed in `REPLY` (not `return`).

### Modules

- arg
  - named and positional argument parsing
- arr
  - join, split, unique...
- common
  - eq, is_null, guard...
- debug
  - interactive debugging
- dir
  - make, remove, exists...
- file
  - read, write, make_with_dir...
- fn
  - list, show, edit...
- int
  - gteq, lteq, eq...
- io
  - empty, oneline, indent...
- mode
  - interactive mode
- status
  - abstract exit status handling
- str
  - color, is_path_like, gsub...
- t
  - testing framework

### Testing

This library provides a testing framework for writing and running tests.
Tests are written in zsh and use a RSpec-like syntax.

Run `z.t` to run all tests.
z.t accepts the following options.

- `-l, --log`
  - Display test details.
- `-f, --failed`
  - Display only failed tests.
- `-c, --compact`
  - Display compact dot output (`.` for success, `F` for failure, `*` for pending).

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

```zsh
my.function() {
  local var="hello"
  z.debug
  z.io $var
}
```

## Mode

This library provides an interactive mode.
It is similar to debug, but with a prefix applied to the functions being executed.
For example, it is used in operations such as git, where the motivation is to avoid repeatedly typing 'git' as a prefix.

```zsh
$ z.mode git
git> status
git> add file.txt
git> commit -m "Add file.txt"
git> push origin branch
git> q
$
```

```zsh
$ z.mode z.io split="."
z.io> oneline "This.is.a.test"
z.io> indent level=2 "Indented line"
z.io> q
$
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
  - Function not found with suggestion
  - Empty line
    - Start of file
    - Whitespace only line
    - Final newline
  - Unused function arguments
  - Missing required positional arguments
  - Missing required named arguments
  - Suppression comment (`# zls: ignore`)
