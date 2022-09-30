//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
// various types
//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄

type nestedBookmark = {
  id: string,
  name: string,
  url: string,
}

type rec nestedFolder = {
  id: string,
  name: string,
  parentId: Js.Nullable.t<string>,
  bookmarks: array<nestedBookmark>, // contained bookmarks
  folders: array<nestedFolder>, // child folders
}

// type FolderMap = { [folderId: string]: NestedFolder }

//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
// create nested stucture of folders/bookmarks
//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
let finalNestedFolderStructure = folders => {
  let unkeyedFoldersAccum = []

  Js.Dict.entries(folders)->Js.Array2.forEach(((_id, folder)) => {
    Js.log(folder)->ignore
    switch Js.Nullable.toOption(folder.parentId) {
    | Some(parentId) => {
        Js.log(`pushing ${folder.id} onto ${parentId} `)
        let parent = Js.Dict.unsafeGet(folders, parentId)
        Js.Array2.push(parent.folders, folder)->ignore
      }

    | None => Js.Array2.push(unkeyedFoldersAccum, folder)->ignore
    }
  })

  //   let unkeyedFolders: NestedFolder[] = []
  //   for (const [folderKey, folderData] of Object.entries(folders)) {
  // Put folder in its parent (keeping its original reference by key inplace,
  // in case it itself is a parent, meaning folder will exist both at top
  // level with a key and inside parent folder).  This will build up a nested
  // data structure of parent/child folders without ever having to go more
  // than one level deep.
  //     if (folderData.folderId) {
  //       folders[folderData.folderId]?.folders.push(folderData)
  //     } else {
  //move top folders to accumulator
  //       unkeyedFolders.push(folders[folderKey]!)
  //     }
  //   }

  unkeyedFoldersAccum
  //   return unkeyedFolders
}

//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
// Gather database rows of bookmarks into object keyed by folderId to make it
// easier to convert eventually to nested array of folders/bookmarks.  Basically
// a groupBy() that also populates bookmarks array
//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
let gatherBookmarksKeyedByFolder = (rows: array<DalData.t>) => {
  let folderMap = Js.Dict.empty()

  Js.Array2.forEach(rows, dataRow => {
    switch Js.Dict.get(folderMap, dataRow.foldersId) {
    // add folder to dict
    | None => {
        let nf: nestedFolder = {
          id: dataRow.foldersId,
          name: dataRow.foldersName,
          parentId: dataRow.parentId,
          bookmarks: [], // contained bookmarks
          folders: [], // child folders
        }
        Js.Dict.set(folderMap, dataRow.foldersId, nf)
      }

    | Some(row) => {
        let nbm: nestedBookmark = {
          id: Js.Nullable.fromOption(dataRow.bookmarksId),
          name: dataRow.bookmarksName,
          url: dataRow.bookmarksUrl,
        }
        Js.Array2.push(row.bookmarks, nbm)->ignore
      }
    }
  })

  folderMap
}

//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
//
//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
let userBookmarkData = (db: Setup.pool, accountId: string) => {
  Promise.resolve()
  ->Promise.then(() => {
    DalData.userBookmarkData(db, accountId)
  })
  ->Promise.thenResolve(data => {
    gatherBookmarksKeyedByFolder(data)
  })
  ->Promise.thenResolve(data => {
    finalNestedFolderStructure(data)
  })
}
