module Webnative.Permissions exposing (BranchFileSystemPermissions, FileSystemPermissions, Permissions, encode, encodeFileSystemPermissions, flattenPermissions)

{-|

@docs BranchFileSystemPermissions, FileSystemPermissions, Permissions, encode, encodeFileSystemPermissions, flattenPermissions

-}

import Json.Encode as Json
import Maybe.Extra as Maybe
import Webnative.AppInfo as AppInfo exposing (AppInfo)
import Webnative.Path as Path exposing (Kind(..), Path)



-- 🌳


{-| Filesystem permissions for a branch.

This is reused for the private and public permissions.

-}
type alias BranchFileSystemPermissions =
    { directories : List (Path Path.Directory)
    , files : List (Path Path.File)
    }


{-| Filesystem permissions.

    ```elm
    import Webnative.Path as Path

    { private =
        { directories = [ Path.directory [ "Audio", "Mixtapes" ] ]
        , files = [ Path.file [ "Audio", "Playlists", "Jazz.json" ] ]
        }
    , public =
        { directories = []
        , files = []
        }
    }
    ```

-}
type alias FileSystemPermissions =
    { private : BranchFileSystemPermissions
    , public : BranchFileSystemPermissions
    }


{-| Permissions to ask the user.
See [`AppPermissions`](#AppPermissions) and [`FileSystemPermissions`](#FileSystemPermissions) on how to use these.
-}
type alias Permissions =
    { app : Maybe AppInfo
    , fs : Maybe FileSystemPermissions
    }



-- 🛠


{-| -}
encode : Permissions -> Json.Value
encode { app, fs } =
    Json.object
        [ ( "app", Maybe.unwrap Json.null AppInfo.encode app )
        , ( "fs", Maybe.unwrap Json.null encodeFileSystemPermissions fs )
        ]


{-| -}
encodeFileSystemPermissions : FileSystemPermissions -> Json.Value
encodeFileSystemPermissions { private, public } =
    let
        encodeBranch branch =
            List.append
                (List.map Path.encode branch.directories)
                (List.map Path.encode branch.files)
    in
    Json.object
        [ ( "private", Json.list identity (encodeBranch private) )
        , ( "public", Json.list identity (encodeBranch public) )
        ]


{-| -}
flattenPermissions : Permissions -> Maybe Permissions
flattenPermissions permissions =
    case ( permissions.app, permissions.fs ) of
        ( Nothing, Nothing ) ->
            Nothing

        _ ->
            Just permissions
