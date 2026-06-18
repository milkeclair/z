source ${z_main}

z.t.describe "z.git.pull"; {
	z.t.context "引数にoriginが含まれる場合"; {
		z.t.it "git pullを渡された引数で実行する"; {
			z.t.mock name="z.git._hp.arg.has.origin" behavior="return 0"
			z.t.mock name="git"

			z.git.pull origin main

			z.t.mock.result
			z.t.expect.reply "pull origin main"
		}
	}

	z.t.context "引数にdevelopが含まれる場合"; {
		z.t.it "z.git.pull._developを呼び出す"; {
			z.t.mock name="z.git._hp.arg.has.origin" behavior="return 1"
			z.t.mock name="z.git._hp.arg.has.develop" behavior="return 0"
			z.t.mock name="z.git.pull._develop" behavior="z.return called"

			z.git.pull dev

			z.t.expect.reply "called"
		}
	}

	z.t.context "z.git.pull._prが成功した場合"; {
		z.t.it "z.git.pull._currentを呼ばない"; {
			z.t.mock name="z.git._hp.arg.has.origin" behavior="return 1"
			z.t.mock name="z.git._hp.arg.has.develop" behavior="return 1"
			z.t.mock name="z.git.pull._pr" behavior="z.return called"
			z.t.mock name="z.git.pull._current" behavior="z.return current"

			z.git.pull

			z.t.expect.reply "called"
		}
  }

	z.t.context "z.git.pull._prが失敗した場合"; {
		z.t.it "z.git.pull._currentを呼ぶ"; {
			z.t.mock name="z.git._hp.arg.has.origin" behavior="return 1"
			z.t.mock name="z.git._hp.arg.has.develop" behavior="return 1"
			z.t.mock name="z.git.pull._pr" behavior="return 1"
			z.t.mock name="z.git.pull._current" behavior="z.return called"

			z.git.pull

			z.t.expect.reply "called"
		}
	}
}

z.t.describe "z.git.pull._develop"; {
	z.t.context "呼び出した場合"; {
		z.t.it "git pull origin developを実行する"; {
			z.t.mock name="z.io"
			z.t.mock name="z.io.empty"
			z.t.mock name="git"

			z.git.pull._develop

			z.t.mock.result name="git"
			z.t.expect.reply "pull origin develop"
		}
	}
}

z.t.describe "z.git.pull._pr"; {
	z.t.context "現在のブランチにpr番号が含まれる場合"; {
		z.t.it "PR向けのpullを実行する"; {
			z.t.mock name="z.git.branch.current._get" behavior='REPLY="pr/123"'
			z.t.mock name="z.io"
			z.t.mock name="z.io.empty"
			z.t.mock name="gh" behavior='echo feature/register'
			z.t.mock name="git"

			z.git.pull._pr

			z.t.mock.result name="git"
      z.t.expect.reply "pull origin feature/register"
		}

		z.t.it "head branchを取得できない場合はエラーを返す"; {
			z.t.mock name="z.git.branch.current._get" behavior='REPLY="pr/123"'
			z.t.mock name="z.io"
			z.t.mock name="z.io.empty"
			z.t.mock name="z.io.error"
			z.t.mock name="gh" behavior="return 1"
			z.t.mock name="git"

			z.git.pull._pr

			z.t.expect.status 1
			z.t.mock.result name="git"
			z.t.expect.reply.is.null
		}
	}

	z.t.context "現在のブランチにpr番号が含まれない場合"; {
		z.t.it "falseを返す"; {
			z.t.mock name="z.git.branch.current._get" behavior="z.return main"
			z.t.mock name="git"

			z.git.pull._pr

			z.t.expect.status.is.false
			z.t.mock.result name="git"
			z.t.expect.reply.is.null
		}
	}
}

z.t.describe "z.git.pull._current"; {
	z.t.context "呼び出した場合"; {
		z.t.it "現在のブランチへpullする"; {
			z.t.mock name="z.git.branch.current._get" behavior="z.return main"
			z.t.mock name="z.io"
			z.t.mock name="z.io.empty"
			z.t.mock name="git"

			z.git.pull._current

			z.t.mock.result name="git"
			z.t.expect.reply "pull origin main"
		}
	}
}
