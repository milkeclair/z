for reply_file in ${z_root}/lib/t/expect/reply/*.zsh; do
  source $reply_file
done

for reply_is_file in ${z_root}/lib/t/expect/reply/is/*.zsh; do
  source $reply_is_file
done

for reply_is_not_file in ${z_root}/lib/t/expect/reply/is/not/*.zsh; do
  source $reply_is_not_file
done

# expect that REPLY equals expect
#
# $1: expected value
# $skip_unmock?: skip_unmock
# REPLY: null
# return: null
#
# example:
#  REPLY="some value"
#  z.t.expect.reply "some value"
z.t.expect.reply() {
  local expect=$1
  local reply=$REPLY
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t.expect "$reply" "$expect" "skip_unmock=$skip_unmock"
}
