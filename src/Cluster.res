@module("node:cluster") external isPrimary: bool = "isPrimary"
@module("node:cluster") external fork: unit => unit = "fork"
@module("node:cluster") external clusterOn: (string, ('w, 'c, 's) => unit) => unit = "on"
@module("node:os") external cpuCount: unit => array<'a> = "cpus"
@module("node:process") external pid: int = "pid"

clusterOn("exit", (w, c, s) => {
  Js.log(`${w["process"]["pid"]} exited ${c} ${s}`)->ignore
})

let cpuCount = Js.Array2.length(cpuCount())
if isPrimary {
  for _i in 1 to cpuCount {
    fork()
  }
  Js.log("primary started")
} else {
  Server.start()
  Js.log(j`Worker $pid started`)
}
