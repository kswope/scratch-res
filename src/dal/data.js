// export interface DataRow extends mysql.RowDataPacket {
//   foldersId: number
//   foldersFolderId?: number
//   foldersName: string
//   bookmarksId?: number
//   bookmarksName?: string
//   bookmarksUrl?: string
// }

//〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰
//
//〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰

exports.userBookmarkData = async function (db, id) {
  let sql = `
  SELECT
    folders.id           as "foldersId",
    folders.parent_id    as "parentId",
    folders.name         as "foldersName",
    bookmarks.id         as "bookmarksId",
    bookmarks.name       as "bookmarksName",
    bookmarks.url        as "bookmarksUrl"
  FROM
    users
  LEFT JOIN 
    folders ON users.id = folders.user_id 
  LEFT JOIN 
    bookmarks ON folders.id = bookmarks.folder_id
  WHERE
    users.id = $1 
  ORDER by
    bookmarks.id
  `

  let { rows } = await db.query(sql, [id])
  return rows
}
