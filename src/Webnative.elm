module Webnative exposing
    ( redirectToLobby, RedirectTo(..), AppPermissions, FileSystemPermissions, Permissions
    , Request, Response
    )

{-| Generic types across all ports, and general [webnative](https://github.com/fission-suite/webnative#readme) functions.


# Authorisation

@docs redirectToLobby, RedirectTo, AppPermissions, FileSystemPermissions, Permissions


# Ports

Data passing through the ports.

@docs Request, Response

-}

import Json.Encode as Json
import Maybe.Extra as Maybe
import Url exposing (Url)



-- 🌳


{-| Where the authorisation lobby should redirect to after authorisation.
-}
type RedirectTo
    = CurrentUrl
    | RedirectTo Url


{-| Application permissions.
-}
type alias AppPermissions =
    { creator : String
    , name : String
    }


{-| Filesystem permissions.
-}
type alias FileSystemPermissions =
    { privatePaths : List String
    , publicPaths : List String
    }


{-| Permissions to ask the user.
-}
type alias Permissions =
    { app : Maybe AppPermissions
    , fs : Maybe FileSystemPermissions
    }


{-| Request from webnative.
-}
type alias Request =
    { tag : String
    , method : String
    , arguments : List Json.Value
    }


{-| Response from webnative.
-}
type alias Response =
    { tag : String
    , method : String
    , data : Json.Value
    }



-- 📣


{-| Redirect to the authorisation lobby.
-}
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
