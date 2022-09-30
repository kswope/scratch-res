type externalUser = {userName: string, email: Js.Nullable.t<string>}
@module("./data.js") external userFromDb: unit => externalUser = "userFromDb"

switch Js.Nullable.toOption(userFromDb().email) {
| Some(email) => Js.log2("sending email to", email)
| None => Js.log("error: user doesnt want email")
}

// conversion to friendlier user record type
type internalUser = {userName: string, email: option<string>}
let user: internalUser = {
  userName: userFromDb().userName,
  email: Js.Nullable.toOption(userFromDb().email),
}

switch user.email {
| Some(email) => Js.log2("sending email to", email)
| None => Js.log("error: user doesnt want email")
}
