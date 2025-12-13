source ${z_main}

z.t.describe "z.cls.draw"; {
  z.t.context "名前を指定された時"; {
    z.t.it "クラスを定義する"; {
      z.cls.draw "MyClass"; {
        z.cls.attr "attr1"

        z.cls.fn "fn1" '
          echo "This is fn1"
        '
        z.cls.drew
      }

      local list=$(z.cls.list)
      z.t.expect.includes $list "MyClass"

      z.cls.delete "MyClass"
    }
  }

  z.t.context "名前を指定しなかった時"; {
    z.t.it "エラーを返す"; {
      z.cls.draw ""

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.cls.attr"; {
  z.t.context "クラス定義中に属性を追加した時"; {
    z.t.it "属性がクラスに追加される"; {
      z.cls.draw "AttrClass"; {
        z.cls.attr "name"
        z.cls.drew
      }

      z.cls.attr.list "AttrClass"
      z.t.expect.reply.includes "name"

      z.cls.delete "AttrClass"
    }
  }

  z.t.context "クラス定義中でない時に属性を追加しようとした時"; {
    z.t.it "エラーを返す"; {
      z.cls.attr "invalidAttr"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.cls.fn"; {
  z.t.context "クラス定義中にメソッドを追加した時"; {
    z.t.it "メソッドがクラスに追加される"; {
      z.cls.draw "FnClass"; {
        z.cls.fn "greet" '
          echo "Hello, $1!"
        '
        z.cls.drew
      }

      z.cls.fn.list "FnClass"
      z.t.expect.reply.includes "greet"

      z.cls.delete "FnClass"
    }

    z.t.it "メソッドが正しく動作する"; {
      z.cls.draw "FnClass"; {
        z.cls.fn "add" '
          echo $(( $1 + $2 ))
        '
        z.cls.drew
      }

      local output=$(z.cls.fn.call "FnClass.add" 3 5)
      z.t.expect $output "8"

      z.cls.delete "FnClass"
    }
  }

  z.t.context "クラス定義中でない時にメソッドを追加しようとした時"; {
    z.t.it "エラーを返す"; {
      z.cls.fn "invalidFn" 'echo "This should fail"'

      z.t.expect.status.is.false
    }
  }

  z.t.context "複数行のメソッドを追加した時"; {
    z.t.it "メソッドが正しく動作する"; {
      z.cls.draw "MultiLineFnClass"; {
        z.cls.fn "complexCalculation" '
          local result=$(( $1 * $2 ))
          result=$(( result + 10 ))
          echo $result
        '
        z.cls.drew
      }

      local output=$(z.cls.fn.call "MultiLineFnClass.complexCalculation" 4 5)
      z.t.expect $output "30"

      z.cls.delete "MultiLineFnClass"
    }
  }
}
