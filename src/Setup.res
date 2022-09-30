// database pool
type pool
@module("pg") @new external pool: unit => pool = "Pool"

// dotenv
@module("dotenv") external dotenv: unit => unit = "config"
