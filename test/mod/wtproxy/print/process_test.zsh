source ${z_main}

z.t.describe "z.wtproxy._print.entry"; {
  z.t.context "entryを指定した場合"; {
    z.t.it "entryとport mappingを出力する"; {
      z.t.mock name="z.wtproxy._config" behavior='
        local -A config=(host 127.0.0.1 proxy_port_1 3000)
        z.return.hash config
      '
      z.t.mock name="z.io"

      z.wtproxy._print.entry \
        path /tmp/worktree \
        branch feat/example \
        compose_project_name project_feat \
        worktree_port_1 3001

      z.t.mock.result name="z.io"
      z.t.expect.reply.is.arr \
        "path: /tmp/worktree" \
        "branch: feat/example" \
        "compose_project_name: project_feat" \
        "worktree_port_1: 127.0.0.1:3000 -> 127.0.0.1:3001"
    }
  }
}
