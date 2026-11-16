# z.reload

Reload `$HOME/.zshrc` in the current shell.

## Installation

```zsh
z.install.mod reload
```

## Usage

```zsh
z.reload
```

The command runs `source "$HOME/.zshrc"` and preserves the configuration's
output, `REPLY` and exit status. An absent file is reported by Zsh and returns
status 127. The path is always `$HOME/.zshrc`, including when `ZDOTDIR` is set.
Shell state follows the normal rules for sourcing a file inside a function.
