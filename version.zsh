# 現在のバージョンを表示する
#
# REPLY: null
# return: null
#
# example:
#  z.version #=> v... (current version)
z.version() {
  z.io "v3.1.0"
}

# GitHubから取得した最新バージョンを表示する
#
# REPLY: null
# return: null
#
# example:
#  z.version.latest #=> v... (latest version)
z.version.latest() {
  local api_url="https://api.github.com/repos/milkeclair/z/releases/latest"
  local response
  response=$(curl -fsSL $api_url)
  z.status.is.false && z.io.error "failed to fetch latest version" && return 1

  local tag_name
  tag_name=$(jq -r '.tag_name // empty' <<< "$response")
  z.is.null $tag_name && return 1

  z.io $tag_name
}

# 現在のバージョンのリリースノートを表示する
#
# REPLY: null
# return: null
#
# example:
#  z.version.latest.note #=> "release note for v... (latest version)"
z.version.latest.note() {
  local api_url="https://api.github.com/repos/milkeclair/z/releases/latest"
  local response
  response=$(curl -fsSL $api_url)
  z.status.is.false && z.io.error "failed to fetch latest release note" && return 1

  local body
  body=$(jq -r '.body // empty' <<< "$response")
  z.is.null $body && return 1

  z.io "$body"
}

# 現在のバージョンのリリースノートを表示する
#
# REPLY: null
# return: null
#
# example:
#  z.version.note #=> "release note for v... (current version)"
z.version.note() {
  local current_version=$(z.version)
  local api_url="https://api.github.com/repos/milkeclair/z/releases/tags/${current_version}"
  local response
  response=$(curl -fsSL $api_url)
  z.status.is.false && z.io.error "failed to fetch release note" && return 1

  local body
  body=$(jq -r '.body // empty' <<< "$response")
  z.is.null $body && return 1

  z.io "$body"
}
