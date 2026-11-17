# ファイルから関数ドキュメントのキャッシュを作成する
#
# $1: ソースファイルのパス
# REPLY: null
# return: null
#
# example:
#  # /tmp/example.zshにz.exampleの定義と「使用例」という説明があり、関数も読み込み済みの場合
#  z.completion.cache.build.docs._from_file /tmp/example.zsh
#  # 変更後: z_completion_docs[z.example]="使用例"
z.completion.cache.build.docs._from_file() {
  setopt local_options EXTENDED_GLOB

  local file_path=$1
  z.file.read path=$file_path
  local lines=("${(@f)REPLY}")
  local line_count=${#lines[@]}
  local idx=0
  local docs_lines=()

  for ((idx=1; idx<=line_count; idx++)); do
    local line=${lines[$idx]}
    if z.completion.cache.build.line.is._comment "$line"; then
      docs_lines+=("$line")
      continue
    fi

    local trimmed_line=$REPLY
    if z.completion.cache.build.line._function_name "$line" "$trimmed_line"; then
      local function_name=$REPLY
      if z.int.is.positive ${+functions[$function_name]} &&
        z.int.is.positive ${#docs_lines[@]}; then
        z.arr.join.line "${docs_lines[@]}"
        z.help._strip_comment_prefix "$REPLY"
        local docs=$REPLY
        z.completion.argument._docs "$docs"
        if z.is.not.null "$REPLY"; then
          z_completion_argument_specs[$function_name]=$REPLY
        else
          unset "z_completion_argument_specs[$function_name]"
        fi
        z.help._normalize_docs "$docs"
        z_completion_docs[$function_name]=$REPLY
      fi
    fi

    docs_lines=()
  done
}
