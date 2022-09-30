type t = {
  id: int,
  email: string,
  password: string,
}

@module("./user.js") external get: (Setup.pool, string) => Promise.t<option<t>> = "get"
