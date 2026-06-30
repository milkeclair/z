source ${z_main}

z.t.describe "z.completion.cache.build.docs._from_file"; {
  z.t.context "docsが関数宣言の直前にある場合"; {
    z.t.it "正規化されたdocsをcacheする"; {
      local fixture_root=/tmp/z_t/completion_cache_build_docs_from_file_root
      local fixture_file=$fixture_root/lib/fixture/process.zsh
      z.fixture.with_docs() { : } # zls: ignore
      z.dir.remove path=$fixture_root
      z.dir.make path=${fixture_file:h}
      z.file.write path=$fixture_file content=$'# fixture docs\n#\n# $1: value\nz.fixture.with_docs() {'
      z_completion_docs=()

      z.completion.cache.build.docs._from_file $fixture_file
      local docs=${z_completion_docs[z.fixture.with_docs]} # zls: ignore
      unfunction z.fixture.with_docs # zls: ignore
      z.dir.remove path=$fixture_root

      z.t.expect "$docs" $'fixture docs\n\n$1: value'
    }
  }

  z.t.context "docsと関数宣言の間に非comment行がある場合"; {
    z.t.it "docsをcacheしない"; {
      local fixture_root=/tmp/z_t/completion_cache_build_docs_from_file_root
      local fixture_file=$fixture_root/lib/fixture/process.zsh
      z.fixture.without_docs() { : } # zls: ignore
      z.dir.remove path=$fixture_root
      z.dir.make path=${fixture_file:h}
      z.file.write path=$fixture_file content=$'# stale docs\nlocal value=1\nz.fixture.without_docs() {'
      z_completion_docs=()

      z.completion.cache.build.docs._from_file $fixture_file
      local docs=${z_completion_docs[z.fixture.without_docs]} # zls: ignore
      unfunction z.fixture.without_docs # zls: ignore
      z.dir.remove path=$fixture_root

      z.t.expect.is.null "$docs"
    }
  }

  z.t.context "docsなしで関数宣言がある場合"; {
    z.t.it "docsをcacheしない"; {
      local fixture_root=/tmp/z_t/completion_cache_build_docs_from_file_root
      local fixture_file=$fixture_root/lib/fixture/process.zsh
      z.fixture.no_docs() { : } # zls: ignore
      z.dir.remove path=$fixture_root
      z.dir.make path=${fixture_file:h}
      z.file.write path=$fixture_file content='z.fixture.no_docs() {'
      z_completion_docs=()

      z.completion.cache.build.docs._from_file $fixture_file
      local docs=${z_completion_docs[z.fixture.no_docs]} # zls: ignore
      unfunction z.fixture.no_docs # zls: ignore
      z.dir.remove path=$fixture_root

      z.t.expect.is.null "$docs"
    }
  }

  z.t.context "関数が未定義の場合"; {
    z.t.it "docsをcacheしない"; {
      local fixture_root=/tmp/z_t/completion_cache_build_docs_from_file_root
      local fixture_file=$fixture_root/lib/fixture/process.zsh
      z.dir.remove path=$fixture_root
      z.dir.make path=${fixture_file:h}
      z.file.write path=$fixture_file content=$'# missing docs\nz.fixture.missing_docs() {'
      z_completion_docs=()

      z.completion.cache.build.docs._from_file $fixture_file
      local docs=${z_completion_docs[z.fixture.missing_docs]} # zls: ignore
      z.dir.remove path=$fixture_root

      z.t.expect.is.null "$docs"
    }
  }

  z.t.context "同じfileに複数の関数がある場合"; {
    z.t.it "関数ごとにdocsを分離してcacheする"; {
      local fixture_root=/tmp/z_t/completion_cache_build_docs_from_file_root
      local fixture_file=$fixture_root/lib/fixture/process.zsh
      z.fixture.first_docs() { : } # zls: ignore
      z.fixture.second_docs() { : } # zls: ignore
      z.dir.remove path=$fixture_root
      z.dir.make path=${fixture_file:h}
      z.file.write path=$fixture_file content=$'# first docs\nz.fixture.first_docs() {\n# second docs\n#\n# example\nz.fixture.second_docs() {'
      z_completion_docs=()

      z.completion.cache.build.docs._from_file $fixture_file
      local first_docs=${z_completion_docs[z.fixture.first_docs]} # zls: ignore
      local second_docs=${z_completion_docs[z.fixture.second_docs]} # zls: ignore
      unfunction z.fixture.first_docs # zls: ignore
      unfunction z.fixture.second_docs # zls: ignore
      z.dir.remove path=$fixture_root

      z.t.expect "$first_docs" "first docs"
      z.t.expect "$second_docs" $'second docs\n\nexample'
    }
  }

  z.t.context "未定義関数の次に定義済み関数がある場合"; {
    z.t.it "未定義関数のdocsを次の関数へ引き継がない"; {
      local fixture_root=/tmp/z_t/completion_cache_build_docs_from_file_root
      local fixture_file=$fixture_root/lib/fixture/process.zsh
      z.fixture.after_missing_docs() { : } # zls: ignore
      z.dir.remove path=$fixture_root
      z.dir.make path=${fixture_file:h}
      z.file.write path=$fixture_file content=$'# missing docs\nz.fixture.missing_docs() {\nz.fixture.after_missing_docs() {'
      z_completion_docs=()

      z.completion.cache.build.docs._from_file $fixture_file
      local missing_docs=${z_completion_docs[z.fixture.missing_docs]} # zls: ignore
      local after_docs=${z_completion_docs[z.fixture.after_missing_docs]} # zls: ignore
      unfunction z.fixture.after_missing_docs # zls: ignore
      z.dir.remove path=$fixture_root

      z.t.expect.is.null "$missing_docs"
      z.t.expect.is.null "$after_docs"
    }
  }
}
