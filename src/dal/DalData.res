type t = {
  foldersId: string,
  parentId: Js.Nullable.t<string>,
  foldersName: string,
  bookmarksId: Js.Nullable.t<string>,
  bookmarksName: Js.Nullable.t<string>,
  bookmarksUrl: Js.Nullable.t<string>,
}

@module("./data.js")
external userBookmarkData: (Setup.pool, string) => Promise.t<array<t>> = "userBookmarkData"
