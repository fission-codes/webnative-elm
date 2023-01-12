module Webnative.Configuration exposing (Configuration, FileSystemConfiguration, encode, encodeFileSystemConfiguration, fromNamespace)

{-|

@docs Configuration, FileSystemConfiguration, encode, encodeFileSystemConfiguration, fromNamespace

-}

import Json.Encode as Json
import Maybe.Extra as Maybe
import Webnative.Namespace as Namespace exposing (Namespace)
import Webnative.Permissions as Permissions exposing (Permissions)



-- 🌳


{-| -}
type alias Configuration =
    { namespace : Namespace

    --
    , debug : Maybe Bool
    , fileSystem : Maybe FileSystemConfiguration
    , permissions : Maybe Permissions
    }


{-| -}
type alias FileSystemConfiguration =
    { loadImmediately : Maybe Bool
    , version : Maybe String
    }



-- 🛠


{-| -}
encode : Configuration -> Json.Value
encode { namespace, debug, permissions, fileSystem } =
    Json.object
        [ ( "namespace", Json.string (Namespace.toString namespace) )

        --
        , ( "debug", Maybe.unwrap Json.null Json.bool debug )
        , ( "fileSystem", Maybe.unwrap Json.null encodeFileSystemConfiguration fileSystem )
        , ( "permissions", Maybe.unwrap Json.null Permissions.encode permissions )
        ]


{-| -}
encodeFileSystemConfiguration : FileSystemConfiguration -> Json.Value
encodeFileSystemConfiguration { loadImmediately, version } =
    Json.object
        [ ( "loadImmediately", Maybe.unwrap Json.null Json.bool loadImmediately )
        , ( "version", Maybe.unwrap Json.null Json.string version )
        ]


{-| -}
fromNamespace : Namespace -> Configuration
fromNamespace namespace =
    { namespace = namespace

    --
    , debug = Nothing
    , permissions = Nothing

    --
    , fileSystem = Nothing
    }
