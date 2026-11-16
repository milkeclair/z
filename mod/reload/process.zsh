# reload the home directory's Zsh configuration in the current shell
#
# REPLY: value left by the sourced configuration
# return: source exit status
#
# example:
#  z.reload
z.reload() {
  source "$HOME/.zshrc"
}
