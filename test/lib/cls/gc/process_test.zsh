source "$z_main"

z.t.describe "z.cls.gc._collect"; {
  z.t.context "関数内で短命のインスタンスを繰り返し作る場合"; {
    z.t.it "生成したインスタンスをスクリプト実行中に回収する"; {
      () {
        local -A z_cls_instances=() z_cls_scalars=() z_cls_references=() z_cls_owner_refs=()
        local -A z_cls_active=() z_cls_owner_markers=()
        local -i z_cls_gc_allocations=0

        z.cls.draw CollectInLoop
        z.cls.drew

        {
          repeat 70; do
            () {
              local counter=""
              z.cls.new CollectInLoop counter
            } || return
          done

          z.hash.count z_cls_instances
          z.int.is.lt "$REPLY" 70
        } always {
          z_cls_gc_allocations=64
          z.cls.gc._collect
        }
      }

      z.t.expect.status.is.true
    }

    z.t.it "同名の所有変数がスコープ外に残るインスタンスを保持する"; {
      () {
        z.cls.draw KeepOuterOwner
          z.cls.attr count default=10
        z.cls.drew

        local counter=""
        z.cls.new KeepOuterOwner counter

        () {
          local counter=""
          z.cls.new KeepOuterOwner counter
        }

        z_cls_gc_allocations=64
        z.cls.gc._collect
        $counter.count.get

        z.t.expect.reply 10

        z.cls.delete counter
      }
    }
  }

  z.t.context "所有者のスコープが終了した場合"; {
    z.t.it "実行中のインスタンスを保持する"; {
      () {
        z.cls.draw KeepRunningInstance
        z.cls.drew

        local instance=""
        () {
          local counter=""
          z.cls.new KeepRunningInstance counter
          instance=$counter
        }
        z_cls_active[$instance]=1

        z_cls_gc_allocations=64
        z.cls.gc._collect

        z.var.exists "z_cls_instances[$instance]"

        z.t.expect.status.is.true

        unset "z_cls_active[$instance]"
        z_cls_gc_allocations=64
        z.cls.gc._collect
      }
    }

    z.t.it "マーク名が空のインスタンスを回収する"; {
      () {
        z.cls.draw CollectUnmarkedInstance
        z.cls.drew

        local counter=""
        z.cls.new CollectUnmarkedInstance counter
        z_cls_owner_markers[$counter]=""
        z_cls_gc_allocations=64

        z.cls.gc._collect

        z.var.exists "z_cls_instances[$counter]"

        z.t.expect.status.is.false
      }
    }
  }
}
