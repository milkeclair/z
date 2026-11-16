# コミットメッセージを組み立てる
#
# $tag: コミットタグ（例: feat、fix）
# $message: コミットメッセージ
# $ticket?: チケット番号（任意）
# $cycle?: TDDサイクル（任意）
#
# REPLY: コミットメッセージ
# return: null
#
# example:
#   z.git.commit._msg.build tag="feat" message="add new feature" ticket="TICKET-123" cycle="red"
#   #=> "feat: #TICKET-123 [red] add new feature"
z.git.commit._msg.build() {
  z.arg.named tag $@ && local tag=$REPLY
  z.arg.named message $@ && local message=$REPLY
  z.arg.named ticket $@ && local ticket=$REPLY
  z.arg.named cycle $@ && local cycle=$REPLY

  local commit_message="$tag: "
  z.is.not.null $ticket && commit_message+="#$ticket "
  z.is.not.null $cycle && commit_message+="[$cycle] "
  commit_message+=$message

  REPLY=$commit_message
}
