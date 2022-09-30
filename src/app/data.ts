import { userBookmarkData as dalUserBookmarkData } from "../dal/data"
import type { DataRow } from "../dal/data"
import * as db from "../lib/db"
import * as pg from "pg"

//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
// various types
//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
type NestedFolder = {
  id: number
  name: string
  folderId?: number // parent folder
  bookmarks: NestedBookmark[] // contained bookmarks
  folders: NestedFolder[] // child folders
}

type NestedBookmark = {
  id: number
  name: string
  url: string
}

type FolderMap = { [folderId: string]: NestedFolder }

//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
// create nested stucture of folders/bookmarks
//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
function finalNestedFolderStructure(folders: FolderMap) {
  let unkeyedFolders: NestedFolder[] = []
  for (const [folderKey, folderData] of Object.entries(folders)) {
    // Put folder in its parent (keeping its original reference by key inplace,
    // in case it itself is a parent, meaning folder will exist both at top
    // level with a key and inside parent folder).  This will build up a nested
    // data structure of parent/child folders without ever having to go more
    // than one level deep.
    if (folderData.folderId) {
      folders[folderData.folderId]?.folders.push(folderData)
    } else {
      //move top folders to accumulator
      unkeyedFolders.push(folders[folderKey]!)
    }
  }

  return unkeyedFolders
}

//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
// Gather database rows of bookmarks into object keyed by folderId to make it
// easier to convert eventually to nested array of folders/bookmarks.  Basically
// a groupBy() that also populates bookmarks array
//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
function gatherBookmarksKeyedByFolder(rows: DataRow[]): FolderMap {
  let rowHash: FolderMap = {}
  for (let row of rows) {
    let folderId = row.foldersId

    // if folder not yet in hash
    if (!(folderId in rowHash)) {
      rowHash[folderId] = {
        id: row.foldersId,
        folderId: row.foldersFolderId,
        name: row.foldersName,
        bookmarks: [],
        folders: [],
      }
    }

    // row contains bookmark data, insert into folder
    if (row.bookmarksId != null) {
      // push bookmark data into bookmarks array if there is data
      let bookmark: NestedBookmark = {
        id: row.bookmarksId,
        // these wont be null if row.bookmarksId is !== null
        name: row.bookmarksName!,
        url: row.bookmarksUrl!,
      }

      rowHash[folderId]!.bookmarks.push(bookmark)
    }
  }
  return rowHash
}

//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
//
//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
export async function userBookmarkData(db: pg.Pool, accountId: number) {
  let rows = await dalUserBookmarkData(db, accountId)
  let rows2 = gatherBookmarksKeyedByFolder(rows)
  let rows3 = finalNestedFolderStructure(rows2)
  return rows3
}
