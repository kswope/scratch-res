exports.get = async function (db, id) {
  let q = "select * from users where id=$1"
  let {
    rows: [user],
  } = await db.query(q, [id])
  return user
}
