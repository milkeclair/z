source ${z_main}

z.t.describe "z.arr.sort.numeric._keys"; {
  z.t.context "符号と先頭ゼロを含む場合"; {
    z.t.it "比較用の数値と元の位置を返す"; {
      z.arr.sort.numeric._keys +02 -000 -0010
      z.t.expect.reply.is.arr "2:1" "0:2" "-10:3"
    }
  }

  z.t.context "空配列の場合"; {
    z.t.it "空配列を返す"; {
      z.arr.sort.numeric._keys
      z.t.expect.reply.is.arr
    }
  }

  z.t.context "errexitが有効な場合"; {
    z.t.it "正常な整数の処理を途中終了せず完了する"; {
      local result=$(
        setopt errexit
        z.arr.sort.numeric._keys 1
        print -r -- "$REPLY[1]"
      )

      z.t.expect "$result" "1:1"
    }
  }

  z.t.context "整数でない要素の場合"; {
    z.t.it "失敗する"; {
      z.arr.sort.numeric._keys "x"
      z.t.expect.status.is.false
    }
  }
}
