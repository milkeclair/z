z.version() {
  z.io "v0.1.0"
}

z.version.latest() {
  local api_url="https://api.github.com/repos/milkeclair/z/releases/latest"
  local response
  response=$(command curl -fsSL $api_url)
  z.status.is.false && z.io.error "failed to fetch latest version" && return 1

  local tag_name
  tag_name=$(command jq -r '.tag_name // empty' <<< "$response")
  z.is.null $tag_name && return 1

  z.io $tag_name
}

z.version.latest.note() {
  local api_url="https://api.github.com/repos/milkeclair/z/releases/latest"
  local response
  response=$(command curl -fsSL $api_url)
  z.status.is.false && z.io.error "failed to fetch latest release note" && return 1

  local body
  body=$(command jq -r '.body // empty' <<< "$response")
  z.is.null $body && return 1

  z.io "$body"
}

z.version.note() {
  local current_version=$(z.version)
  local api_url="https://api.github.com/repos/milkeclair/z/releases/tags/${current_version}"
  local response
  response=$(command curl -fsSL $api_url)
  z.status.is.false && z.io.error "failed to fetch release note" && return 1

  local body
  body=$(command jq -r '.body // empty' <<< "$response")
  z.is.null $body && return 1

  z.io "$body"
}
