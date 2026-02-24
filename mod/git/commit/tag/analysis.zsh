z.git.commit.tag.list() {
  local tags=(
    feat
    fix
    chore
    docs
    style
    refactor
    test
  )

  z.return $tags
}
