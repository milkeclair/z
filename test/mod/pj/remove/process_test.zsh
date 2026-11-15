source ${z_main}
local fixture_root="/tmp/z_t/pj_select_$$"

z.t.describe "z.pj.remove._select"; {
  z.t.it "名前順の番号に対応する名前を返す"; {
    local XDG_CONFIG_HOME="$fixture_root/selected"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    touch "$XDG_CONFIG_HOME/z/pj/alpha" "$XDG_CONFIG_HOME/z/pj/zeta"
    z.pj.remove._select <<< '2' 2>/dev/null
    local result_code=$?
    local selected=$REPLY
    z.t.expect "$result_code" 0
    z.t.expect "$selected" zeta
  }
  z.t.it "未登録の場合は入力を求めず空で成功する"; {
    local XDG_CONFIG_HOME="$fixture_root/empty"
    z.pj.remove._select </dev/null 2>/dev/null
    local result_code=$?
    local selected=$REPLY
    z.t.expect "$result_code" 0
    z.t.expect "$selected" ""
  }
  z.t.it "候補外の番号は失敗し登録を変えない"; {
    local XDG_CONFIG_HOME="$fixture_root/out_of_range"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    touch "$XDG_CONFIG_HOME/z/pj/example"
    z.pj.remove._select <<< 999999999999999999999999999 2>/dev/null
    local result_code=$?
    local selected=$REPLY
    z.t.expect "$result_code" 1
    z.t.expect "$selected" ""
  }
}
