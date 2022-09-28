let app = Polka.make()

let app = Polka.use(app, (_req, res, next) => {
  res->Polka.jsonEnd({"error!": 400})
  next()
})

let app = Polka.get(app, "/user", (_req, res) => {
  res->Polka.end("hello!!!")
})

Polka.listen(app, 3000, () => Js.log("starting"))
