# build commit message
#
# $tag: commit tag (e.g. feat, fix)
# $message: commit message
# $ticket?: ticket number (optional)
# $cycle?: tdd cycle (optional)
#
# REPLY: commit message
# return: null
#
# example:
#   z.git.commit.msg.build tag="feat" message="add new feature" ticket="TICKET-123" cycle="red"
#   #=> "feat: #TICKET-123 [red] add new feature"
z.git.commit.msg.build() {
  z.arg.named tag $@ && local tag=$REPLY
  z.arg.named message $@ && local message=$REPLY
  z.arg.named ticket $@ && local ticket=$REPLY
  z.arg.named cycle $@ && local cycle=$REPLY

  local commit_message="$tag: "
  z.is.not.null $ticket && commit_message+="#$ticket "
  z.is.not.null $cycle && commit_message+="[$cycle] "
  commit_message+=$message

  z.return $commit_message
}
