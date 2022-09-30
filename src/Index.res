let app = Polka.make()
Setup.dotenv()

let app = Polka.use(app, (_req, _res, next) => {
  next()
})

// debug
AppData.userBookmarkData(Setup.pool(), "1")
// ->Promise.thenResolve(data => {
//   Js.log(data[0])
// })
->ignore
// /debug

let app = Polka.get(app, "/api/data", (_req, res) => {
  AppData.userBookmarkData(Setup.pool(), "1")
  ->Promise.thenResolve(data => {
    res->Polka.jsonEnd({"data": data})
  })
  ->ignore
})

let app = Polka.get(app, "/user/:id", (req, res) => {
  switch req->Polka.params->Js.Dict.get("id") {
  | None => res->Polka.jsonEnd({"error": "missing id"})
  | Some(id) =>
    DalUser.get(Setup.pool(), id)
    ->Promise.thenResolve(user => {
      switch user {
      | Some(user) => res->Polka.jsonEnd({"user": user})
      | None => res->Polka.jsonEnd({"error": "user not found"})
      }
    })
    ->ignore
  }
})

Polka.listen(app, 3000, () => Js.log("starting"))
