source "$z_main"
source "$z_root/test/mod/completion/complete/terminal.zsh"

if ! z92_terminal_start; then
  zpty -d completion_terminal 2>/dev/null
  exit 1
fi
local terminal_fd=$REPLY

{
z.t.describe "z92_terminal_start"; {
  z.t.context "端末の初期化が完了した場合"; {
    z.t.it "稼働中の端末descriptorを返す"; {
      [[ "$terminal_fd" == <-> ]] && zpty -t completion_terminal

      z.t.expect.status.is.true
    }
  }
}

z.t.describe "z92_terminal_read"; {
  z.t.context "markerがパターン記号を含む場合"; {
    z.t.it "文字列として一致する出力を返す"; {
      zpty -w completion_terminal "print -r -- 'Z92_LITERAL:[*?]'"
      z92_terminal_read "$terminal_fd" $'\r\nZ92_LITERAL:[*?]\r\n'

      z.t.expect.reply.includes $'\r\nZ92_LITERAL:[*?]\r\n'
    }
  }

  z.t.context "出力待機に失敗した場合"; {
    z.t.it "成功扱いせずfalseを返す"; {
      z.t.mock name="zselect" behavior="return 1"

      z92_terminal_read "$terminal_fd" never-arrives >/dev/null 2>&1

      z.t.expect.status.is.false
    }
  }

}

z.t.describe "z92_terminal"; {
  z.t.context "前のケースにaliasがある場合"; {
    z.t.it "次のケースにaliasを持ち越さない"; {
      local with_alias=$(z92_terminal "$terminal_fd" input=z.fixture. setup="alias z.fixture.alias=:")
      local without_alias=$(z92_terminal "$terminal_fd" input=z.fixture.)

      z.t.expect.includes "$with_alias" "matches:lines=3:"
      z.t.expect "$without_alias" $'matches:lines=2:2\nbuffer=z.fixture.'
    }
  }

  z.t.context "前のケースに補完styleがある場合"; {
    z.t.it "次のケースの候補数へ影響させない"; {
      local filtered=$(z92_terminal "$terminal_fd" input=z.fixture. 'setup=zstyle ":completion:*:z-functions" ignored-patterns "z.fixture.beta"')
      local unfiltered=$(z92_terminal "$terminal_fd" input=z.fixture.)

      z.t.expect "$filtered" $'matches:lines=1:1\nbuffer=z.fixture.alpha '
      z.t.expect "$unfiltered" $'matches:lines=2:2\nbuffer=z.fixture.'
    }
  }
}
} always {
  zpty -d completion_terminal
}
