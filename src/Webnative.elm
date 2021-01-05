module Webnative exposing (AppPermissions, FileSystemPermissions, Permissions, RedirectTo(..), Request, Response, redirectToLobby)

import Json.Encode as Json
import Maybe.Extra as Maybe
import Url exposing (Url)



-- 🌳


type RedirectTo
    = CurrentUrl
    | RedirectTo Url


type alias AppPermissions =
    { creator : String
    , name : String
    }


type alias FileSystemPermissions =
    { privatePaths : List String
    , publicPaths : List String
    }


type alias Permissions =
    { app : Maybe AppPermissions
    , fs : Maybe FileSystemPermissions
    }


type alias Request =
    { tag : String
    , method : String
    , arguments : List Json.Value
    }


type alias Response =
    { tag : String
    , method : String
    , data : Json.Value
    }



-- 📣


redirectToLobby : RedirectTo -> Maybe Permissions -> Request
redirectToLobby redirectTo maybePermissions =
    { tag = ""
    , method = "redirectToLobby"
    , arguments =
        [ Maybe.unwrap Json.null encodePermissions maybePermissions
        , case redirectTo of
            CurrentUrl ->
                Json.null

            RedirectTo url ->
                Json.string (Url.toString url)
        ]
    }



-- ㊙️


encodePermissions : Permissions -> Json.Value
encodePermissions { app, fs } =
    Json.object
        [ ( "app", Maybe.unwrap Json.null encodeAppPermissions app )
        , ( "fs", Maybe.unwrap Json.null encodeFileSystemPermissions fs )
        ]


encodeAppPermissions : AppPermissions -> Json.Value
encodeAppPermissions { creator, name } =
    Json.object
        [ ( "creator", Json.string creator )
        , ( "name", Json.string name )
        ]


encodeFileSystemPermissions : FileSystemPermissions -> Json.Value
encodeFileSystemPermissions { privatePaths, publicPaths } =
    Json.object
        [ ( "privatePaths", Json.list Json.string privatePaths )
        , ( "publicPaths", Json.list Json.string publicPaths )
        ]
