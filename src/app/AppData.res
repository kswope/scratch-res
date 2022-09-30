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
  parentId: option<string>,
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
    switch folder.parentId {
    | Some(parentId) => {
        let parent = Js.Dict.unsafeGet(folders, parentId)
        Js.Array2.push(parent.folders, folder)->ignore
      }

    | None => Js.Array2.push(unkeyedFoldersAccum, folder)->ignore
    }
  })

  unkeyedFoldersAccum
}

//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
// Gather database rows of bookmarks into object keyed by folderId to make it
// easier to convert eventually to nested array of folders/bookmarks.  Basically
// a groupBy() that also populates bookmarks array
//┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
let gatherBookmarksKeyedByFolder = (rows: array<DalData.t>) => {
  let folderMap = Js.Dict.empty()

  Js.Array2.forEach(rows, dataRow => {
    // if folder not yet in Dict add it
    if Js.Dict.get(folderMap, dataRow.foldersId)->Js.Option.isNone {
      let nf: nestedFolder = {
        id: dataRow.foldersId,
        name: dataRow.foldersName,
        parentId: Js.Nullable.toOption(dataRow.parentId),
        bookmarks: [], // contained bookmarks
        folders: [], // child folders
      }
      Js.Dict.set(folderMap, dataRow.foldersId, nf)
    }

    // row contains bookmark data, insert into folder
    if Js.Nullable.toOption(dataRow.bookmarksId)->Js.Option.isSome {
      let nbm: nestedBookmark = {
        id: Js.Option.getWithDefault("", Js.Nullable.toOption(dataRow.bookmarksId)),
        name: Js.Option.getWithDefault("", Js.Nullable.toOption(dataRow.bookmarksName)),
        url: Js.Option.getWithDefault("", Js.Nullable.toOption(dataRow.bookmarksUrl)),
      }
      switch Js.Dict.get(folderMap, dataRow.foldersId) {
      | Some(row) => Js.Array2.push(row.bookmarks, nbm)->ignore
      | None => () // this should not happen because folder already added
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
