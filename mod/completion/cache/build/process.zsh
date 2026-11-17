# 関数名だけのキャッシュを作成する
#
# REPLY: null
# return: null
#
# example:
#  # 公開関数z.exampleを読み込み済みの場合
#  z.completion.cache.build._names
#  # z_completion_function_namesの要素例: "z.example"
z.completion.cache.build._names() {
  z_completion_function_names=()
  for function_name in ${(ko)functions}; do
    if z.str.start_with "$function_name" "z." && ! z.completion.function.is._private "$function_name"; then
      z_completion_function_names+=("$function_name")
    fi
  done
}

# 関数ドキュメントのキャッシュを作成する
#
# REPLY: null
# return: null
#
# example:
#  # z_root配下に、説明が「使用例」のz.exampleを定義したファイルがある場合
#  z.completion.cache.build._docs
#  # 変更後: z_completion_docs[z.example]="使用例"
z.completion.cache.build._docs() {
  z_completion_docs=()
  z_completion_argument_specs=()

  local files=(
    "${z_root}"/*.zsh(N)
    "${z_root}"/lib/**/*.zsh(N)
    "${z_root}"/mod/**/*.zsh(N)
  )
  for file_path in $files; do
    z.completion.cache.build.docs._from_file $file_path
  done
}

# 補完キャッシュを作成し、ジョブの結果ファイルへ書き込む
#
# $result: 結果ファイルのパス
# REPLY: null
# return: 0|1
#
# example:
#  # 結果ファイルの親ディレクトリがあり、キャッシュ生成と書き込みが成功する場合
#  z.completion.cache.build._result result=/tmp/z/job/result
#  # return: 0
#  # /tmp/z/job/resultの末尾: z_completion_cache_ready=true
z.completion.cache.build._result() {
  z.arg.named result "$@" && local result=$REPLY
  z.is.null "$result" && return 1

  z.completion.cache._build
  z.completion.cache._dump
  local lines=("${(@f)REPLY}")
  z.file.write path="$result" content=""
  for line in "${lines[@]}"; do
    z.file.write.last path="$result" content="$line"
  done
}
