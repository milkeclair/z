source ${z_main}

z.t.describe "z.git.pull"; {
	z.t.context "引数にoriginが含まれる場合"; {
		z.t.it "git pullを渡された引数で実行する"; {
			z.t.mock name="z.git.hp.arg.has.origin" behavior="return 0"
			z.t.mock name="git"

			z.git.pull origin main

			z.t.mock.result
			z.t.expect.reply "pull origin main"
		}
	}

	z.t.context "引数にdevelopが含まれる場合"; {
		z.t.it "z.git.pull.developを呼び出す"; {
			z.t.mock name="z.git.hp.arg.has.origin" behavior="return 1"
			z.t.mock name="z.git.hp.arg.has.develop" behavior="return 0"
			z.t.mock name="z.git.pull.develop" behavior="z.return called"

			z.git.pull dev

			z.t.expect.reply "called"
		}
	}

	z.t.context "z.git.pull.prが成功した場合"; {
		z.t.it "z.git.pull.currentを呼ばない"; {
			z.t.mock name="z.git.hp.arg.has.origin" behavior="return 1"
			z.t.mock name="z.git.hp.arg.has.develop" behavior="return 1"
			z.t.mock name="z.git.pull.pr" behavior="z.return called"
			z.t.mock name="z.git.pull.current" behavior="z.return current"

			z.git.pull

			z.t.expect.reply "called"
		}
  }

  z.t.context "z.git.pull.prが失敗した場合"; {
		z.t.it "z.git.pull.currentを呼ぶ"; {
			z.t.mock name="z.git.hp.arg.has.origin" behavior="return 1"
			z.t.mock name="z.git.hp.arg.has.develop" behavior="return 1"
			z.t.mock name="z.git.pull.pr" behavior="return 1"
			z.t.mock name="z.git.pull.current" behavior="z.return called"

			z.git.pull

			z.t.expect.reply "called"
		}
	}
}

z.t.describe "z.git.pull.develop"; {
	z.t.context "呼び出した場合"; {
		z.t.it "git pull origin developを実行する"; {
			z.t.mock name="z.io"
			z.t.mock name="z.io.empty"
			z.t.mock name="git"

			z.git.pull.develop

			z.t.mock.result name="git"
			z.t.expect.reply "pull origin develop"
		}
	}
}

z.t.describe "z.git.pull.pr"; {
	z.t.context "現在のブランチにpr番号が含まれる場合"; {
		z.t.it "PR向けのpullを実行する"; {
			z.t.mock name="z.git.branch.current.get" behavior='REPLY="pr/123"'
			z.t.mock name="z.io"
			z.t.mock name="z.io.empty"
			z.t.mock name="git"

			z.git.pull.pr

			z.t.mock.result name="git"
      z.t.expect.reply "pull origin pull/123/head:pr/123"
		}
	}

	z.t.context "現在のブランチにpr番号が含まれない場合"; {
		z.t.it "falseを返す"; {
			z.t.mock name="z.git.branch.current.get" behavior="z.return main"
			z.t.mock name="git"

			z.git.pull.pr

			z.t.expect.status.is.false
			z.t.mock.result name="git"
			z.t.expect.reply.is.null
		}
	}
}

z.t.describe "z.git.pull.current"; {
	z.t.context "呼び出した場合"; {
		z.t.it "現在のブランチへpullする"; {
			z.t.mock name="z.git.branch.current.get" behavior="z.return main"
			z.t.mock name="z.io"
			z.t.mock name="z.io.empty"
			z.t.mock name="git"

			z.git.pull.current

			z.t.mock.result name="git"
			z.t.expect.reply "pull origin main"
		}
	}
}
