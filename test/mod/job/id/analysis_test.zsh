source ${z_main}

z.t.describe "z.job.id._generate"; {
  z.t.context "呼び出された場合"; {
    z.t.it "timestamp、pid、randomを含むidを返す"; {
      z.job.id._generate
      local id=$REPLY

      z.str.split str="$id" delimiter="."
      local parts=("${(@)REPLY}")
      local date_pattern="[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"
      local time_pattern="[0-9][0-9][0-9][0-9][0-9][0-9]"
      local nano_pattern="[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"

      z.t.expect "${#parts[@]}" 3
      z.str.is.match "$parts[1]" "${date_pattern}T${time_pattern}${nano_pattern}"
      z.t.expect.status.is.true
      z.t.expect "$parts[2]" "$$"
      z.int.is.match "$parts[3]"
      z.t.expect.status.is.true
      z.int.is.gteq "$parts[3]" 0
      z.t.expect.status.is.true
      z.int.is.lteq "$parts[3]" 32767
      z.t.expect.status.is.true
    }
  }
}
