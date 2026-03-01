# echo the current version
#
# REPLY: null
# return: null
#
# example:
#  z.version #=> v0.2.0
z.version() {
  z.io "v0.2.0"
}

# echo the latest version from GitHub
#
# REPLY: null
# return: null
#
# example:
#  z.version.latest #=> v0.2.0
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

# echo the release note of the current version
#
# REPLY: null
# return: null
#
# example:
#  z.version.latest.note #=> "release note for v0.2.0"
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

# echo the release note of the current version
#
# REPLY: null
# return: null
#
# example:
#  z.version.note #=> "release note for v0.2.0"
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
