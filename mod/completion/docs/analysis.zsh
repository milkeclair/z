# zの関数の正規化済みドキュメントをキャッシュから取得する
#
# $1: 関数名
# REPLY: 正規化したドキュメント|null
# return: 0|1
#
# example:
#  z_completion_docs[z.arg.get]="引数を取得する"
#  z.completion.docs._get z.arg.get
#  # REPLY: "引数を取得する"
#  # return: 0
z.completion.docs._get() {
  local function_name=$1

  if z.int.is.positive ${+z_completion_docs[$function_name]}; then
    REPLY="${z_completion_docs[$function_name]}"
    return
  fi

  REPLY=""
  return 1
}

# 補完メッセージ用にキャッシュ済みのドキュメントを整形する
#
# $1: 正規化したドキュメント
# REPLY: 通常の%をエスケープし、カラーコードを幅0として扱うドキュメント
# return: null
#
# example:
#  z.completion.docs._format "100% complete"
#  # REPLY: "100%% complete"
z.completion.docs._format() {
  z.str.gsub str="$1" search="%" replace="%%" literal=true
  local docs=$REPLY
  z.str.color cyan
  local argument_color="%{$REPLY%}"
  z.str.color yellow
  local heading_color="%{$REPLY%}"
  z.str.color green
  local example_color="%{$REPLY%}"
  z.str.color reset
  local reset="%{$REPLY%}"
  local in_example=false
  local formatted=()
  local line

  for line in "${(@f)docs}"; do
    if z.is.true $in_example && z.str.is.match "$line" '^[[:space:]]+[^[:space:]]'; then
      formatted+=("${example_color}${line}${reset}")
      continue
    fi

    if z.str.is.match "$line" '^\$[^:[:space:]]+:|^(REPLY|return|example):'; then
      z.str.partition "$line" ":" literal=true
      local label=$REPLY[1] detail=$REPLY[2]
      local color=$heading_color
      z.str.start_with "$label" '$' && color=$argument_color
      in_example=false
      z.is.eq "$label" example && in_example=true
      formatted+=("${color}${label}:${reset}${detail}")
    else
      z.is.not.null "$line" && in_example=false
      formatted+=("$line")
    fi
  done

  REPLY="${(F)formatted}"
}
