module Webnative exposing
    ( init, InitOptions, initWithOptions, initialise, initialize
    , isAuthenticated, State(..), AuthSucceededState, AuthCancelledState, ContinuationState
    , redirectToLobby, RedirectTo(..), AppPermissions, FileSystemPermissions, Permissions
    , decodeResponse, Artifact(..), Request, Response
    , loadFilesystem
    , contextToString, contextFromString, Context(..)
    )

{-| Generic types across all ports, and general [webnative](https://github.com/fission-suite/webnative#readme) functions.


# Getting Started

@docs init, InitOptions, initWithOptions, initialise, initialize


# Authentication

@docs isAuthenticated, State, AuthSucceededState, AuthCancelledState, ContinuationState


# Authorisation

@docs redirectToLobby, RedirectTo, AppPermissions, FileSystemPermissions, Permissions


# Ports

Data passing through the ports.

@docs decodeResponse, Artifact, Request, Response


# Filesystem

@docs loadFilesystem


# Miscellaneous

@docs contextToString, contextFromString, Context

-}

import Bytes exposing (Bytes)
import Dict
import Json.Decode exposing (Decoder)
import Json.Encode as Json
import Maybe.Extra as Maybe
import Url exposing (Url)
import Webnative.Internal as Webnative exposing (..)
import Wnfs.Directory exposing (..)
import Wnfs.Internal as Wnfs exposing (..)



-- 🌳


{-| Artifact we receive in the response.
-}
type Artifact
    = NoArtifact
      -- Webnative
    | Initialisation State
      -- WNFS
    | Boolean Bool
    | CID String
    | DirectoryContent (List Entry)
    | FileContent Bytes
    | Utf8Content String


{-| Request, or response, context.
-}
type Context
    = Webnative
    | Wnfs


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


{-| Options for `initWithOptions`.
-}
type alias InitOptions =
    { autoRemoveUrlParams : Bool
    , loadFilesystem : Bool
    }


{-| Default `InitOptions`.
-}
defaultInitOptions : InitOptions
defaultInitOptions =
    { autoRemoveUrlParams = True
    , loadFilesystem = True
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
    { context : String
    , tag : String
    , method : String
    , arguments : List Json.Value
    }


{-| Response from webnative.
-}
type alias Response =
    { context : String
    , error : Maybe String
    , tag : String
    , method : String
    , data : Json.Value
    }



-- 🌳  ⌘  AUTH


{-| Initialisation state, result from `init`.
-}
type State
    = NotAuthorised
    | AuthSucceeded AuthSucceededState
    | AuthCancelled AuthCancelledState
    | Continuation ContinuationState


{-| State attributes when auth has succeeded.
-}
type alias AuthSucceededState =
    { newUser : Bool, throughLobby : Bool, username : String }


{-| State attributes when auth was cancelled.
-}
type alias AuthCancelledState =
    { cancellationReason : String, throughLobby : Bool }


{-| State attributes when continueing a session.
-}
type alias ContinuationState =
    { newUser : Bool, throughLobby : Bool, username : String }


{-| Are we authenticated?
-}
isAuthenticated : State -> Bool
isAuthenticated state =
    case state of
        NotAuthorised ->
            False

        AuthSucceeded _ ->
            True

        AuthCancelled _ ->
            False

        Continuation _ ->
            True



-- 📣


{-| 🚀 **Start here**

Check if we're authenticated, process any lobby query-parameters present in the URL, and initiate the user's filesystem if authenticated (can be disabled using `initWithOptions`).

See `loadFileSystem` if you want to load the user's filesystem yourself.
**NOTE**, this only works on the main/ui thread, as it uses `window.location`.

See the [README](../) for an example.

-}
init : Permissions -> Request
init =
    initWithOptions defaultInitOptions


{-| Initialise webnative, with options.
-}
initWithOptions : InitOptions -> Permissions -> Request
initWithOptions options permissions =
    { context = contextToString Webnative
    , tag = ""
    , method = Webnative.methodToString Initialise
    , arguments =
        [ Json.object
            [ ( "autoRemoveUrlParams"
              , Json.bool options.autoRemoveUrlParams
              )
            , ( "loadFilesystem"
              , Json.bool options.loadFilesystem
              )
            , ( "permissions"
              , Maybe.unwrap Json.null encodePermissions (flattenPermissions permissions)
              )
            ]
        ]
    }


{-| Alias for `init`.
-}
initialise : Permissions -> Request
initialise =
    init


{-| Alias for `init`.
-}
initialize : Permissions -> Request
initialize =
    init


{-| Load in the filesystem manually.
-}
loadFilesystem : Permissions -> Request
loadFilesystem permissions =
    { context = contextToString Webnative
    , tag = ""
    , method = Webnative.methodToString LoadFilesystem
    , arguments =
        [ Maybe.unwrap
            Json.null
            encodePermissions
            (flattenPermissions permissions)
        ]
    }


{-| Redirect to the authorisation lobby.
-}
redirectToLobby : RedirectTo -> Permissions -> Request
redirectToLobby redirectTo permissions =
    { context = contextToString Webnative
    , tag = ""
    , method = Webnative.methodToString RedirectToLobby
    , arguments =
        [ Maybe.unwrap Json.null encodePermissions (flattenPermissions permissions)
        , case redirectTo of
            CurrentUrl ->
                Json.null

            RedirectTo url ->
                Json.string (Url.toString url)
        ]
    }



-- 📰


{-| Function to be used to decode the response from webnative we got through our port.

    GotWebnativeResponse response ->
      case Webnative.decodeResponse tagFromString response of
        -----------------------------------------
        -- 🚀
        -----------------------------------------
        Ok ( _, _, Initialisation state ) ->
          if Webnative.isAuthenticated state then
            loadUserData
          else
            welcome

        -----------------------------------------
        -- 💾
        -----------------------------------------
        Ok ( Wnfs, Just ReadHelloTxt, Wnfs.Utf8Content helloContents ) ->
          -- Do something with content from hello.txt

        Ok ( Wnfs, Just Mutation, _ ) ->
          ( model
          , Ports.webnativeRequest Wnfs.publish
          )

        -----------------------------------------
        -- 🥵
        -----------------------------------------
        Err ( maybeContext, errString ) ->
          -- Initialisation error, tag parse error, etc.

See the [README](../) for the full example.

-}
decodeResponse :
    (String -> Result String tag)
    -> Response
    -> Result ( Maybe Context, String ) ( Context, Maybe tag, Artifact )
decodeResponse tagParser response =
    case ( response.error, contextFromString response.context ) of
        -----------------------------------------
        -- Errors
        -----------------------------------------
        ( Just "INSECURE_CONTEXT", Just Webnative ) ->
            Err ( Just Webnative, Webnative.error Webnative.InsecureContext "" )

        ( Just "UNSUPPORTED_BROWSER", Just Webnative ) ->
            Err ( Just Webnative, Webnative.error Webnative.UnsupportedBrowser "" )

        ( Just err, maybeContext ) ->
            Err ( maybeContext, err )

        -----------------------------------------
        -- Webnative
        -----------------------------------------
        ( Nothing, Just Webnative ) ->
            response
                |> decodeWebnativeResponse tagParser
                |> Result.map (\( a, b ) -> ( Webnative, a, b ))
                |> Result.mapError (Tuple.pair <| Just Webnative)

        -----------------------------------------
        -- WNFS
        -----------------------------------------
        ( Nothing, Just Wnfs ) ->
            response
                |> decodeWnfsResponse tagParser
                |> Result.map (\( a, b ) -> ( Wnfs, a, b ))
                |> Result.mapError (Tuple.pair <| Just Wnfs)

        -----------------------------------------
        -- 🤷
        -----------------------------------------
        ( Nothing, Nothing ) ->
            Err ( Nothing, "Invalid context" )



-- 🛠


{-| Cast a Context to a String.
-}
contextToString : Context -> String
contextToString context =
    case context of
        Webnative ->
            "WEBNATIVE"

        Wnfs ->
            "WNFS"


{-| Derive a Context from a String.
-}
contextFromString : String -> Maybe Context
contextFromString string =
    case String.toUpper string of
        "WEBNATIVE" ->
            Just Webnative

        "WNFS" ->
            Just Wnfs

        _ ->
            Nothing



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


flattenPermissions : Permissions -> Maybe Permissions
flattenPermissions permissions =
    case ( permissions.app, permissions.fs ) of
        ( Nothing, Nothing ) ->
            Nothing

        _ ->
            Just permissions



-- ㊙️  ⌘  WEBNATIVE RESPONSE


decodeWebnativeResponse : (String -> Result String tag) -> Response -> Result String ( Maybe tag, Artifact )
decodeWebnativeResponse tagParser response =
    case Webnative.methodFromString response.method of
        Nothing ->
            Err (Webnative.error Webnative.InvalidMethod response.method)

        Just method ->
            response.data
                |> Json.Decode.decodeValue
                    (case method of
                        Initialise ->
                            Json.Decode.map Initialisation stateDecoder

                        LoadFilesystem ->
                            Json.Decode.succeed NoArtifact

                        RedirectToLobby ->
                            Json.Decode.succeed NoArtifact
                    )
                |> Result.mapError
                    (Json.Decode.errorToString >> Webnative.error Webnative.DecodingError)
                |> Result.andThen
                    (\artifact ->
                        case response.tag of
                            "" ->
                                Ok ( Nothing, artifact )

                            _ ->
                                response.tag
                                    |> tagParser
                                    |> Result.map (\t -> ( Just t, artifact ))
                    )


stateDecoder : Decoder State
stateDecoder =
    Json.Decode.andThen
        (\scenario ->
            case scenario of
                "NOT_AUTHORISED" ->
                    Json.Decode.succeed NotAuthorised

                "AUTH_SUCCEEDED" ->
                    Json.Decode.map AuthSucceeded authSucceededDecoder

                "AUTH_CANCELLED" ->
                    Json.Decode.map AuthCancelled authCancelledDecoder

                "CONTINUATION" ->
                    Json.Decode.map Continuation continuationDecoder

                other ->
                    Json.Decode.fail "Initialise returned an unknown scenario"
        )
        (Json.Decode.field "scenario" Json.Decode.string)


authSucceededDecoder : Decoder AuthSucceededState
authSucceededDecoder =
    Json.Decode.map3 AuthSucceededState
        (Json.Decode.field "newUser" Json.Decode.bool)
        (Json.Decode.field "throughLobby" Json.Decode.bool)
        (Json.Decode.field "username" Json.Decode.string)


authCancelledDecoder : Decoder AuthCancelledState
authCancelledDecoder =
    Json.Decode.map2 AuthCancelledState
        (Json.Decode.field "cancellationReason" Json.Decode.string)
        (Json.Decode.field "throughLobby" Json.Decode.bool)


continuationDecoder : Decoder ContinuationState
continuationDecoder =
    Json.Decode.map3 ContinuationState
        (Json.Decode.field "newUser" Json.Decode.bool)
        (Json.Decode.field "throughLobby" Json.Decode.bool)
        (Json.Decode.field "username" Json.Decode.string)



-- ㊙️  ⌘  WNFS RESPONSE


decodeWnfsResponse : (String -> Result String tag) -> Response -> Result String ( Maybe tag, Artifact )
decodeWnfsResponse tagParser response =
    case Wnfs.methodFromString response.method of
        Nothing ->
            Err (Wnfs.error Wnfs.InvalidMethod response.method)

        Just method ->
            response.data
                |> Json.Decode.decodeValue
                    (case method of
                        Exists ->
                            Json.Decode.map Boolean Json.Decode.bool

                        Ls ->
                            Json.Decode.map DirectoryContent directoryContentDecoder

                        Mkdir ->
                            Json.Decode.succeed NoArtifact

                        Mv ->
                            Json.Decode.succeed NoArtifact

                        Publish ->
                            Json.Decode.map CID cidDecoder

                        Read ->
                            Json.Decode.map FileContent fileContentDecoder

                        ReadUtf8 ->
                            Json.Decode.map Utf8Content utf8ContentDecoder

                        Rm ->
                            Json.Decode.succeed NoArtifact

                        Write ->
                            Json.Decode.succeed NoArtifact
                    )
                |> Result.mapError
                    (Json.Decode.errorToString >> Wnfs.error Wnfs.DecodingError)
                |> Result.andThen
                    (\artifact ->
                        response.tag
                            |> tagParser
                            |> Result.map (\t -> ( Just t, artifact ))
                    )


directoryContentDecoder : Json.Decode.Decoder (List Entry)
directoryContentDecoder =
    Json.Decode.map3
        (\cid isFile size ->
            { cid = cid
            , size = size
            , kind =
                if isFile then
                    File

                else
                    Directory
            }
        )
        (Json.Decode.oneOf
            [ Json.Decode.field "cid" Json.Decode.string
            , Json.Decode.field "pointer" Json.Decode.string
            ]
        )
        (Json.Decode.field "isFile" Json.Decode.bool)
        (Json.Decode.field "size" Json.Decode.int)
        |> Json.Decode.dict
        |> Json.Decode.map
            (\dict ->
                dict
                    |> Dict.toList
                    |> List.map
                        (\( name, { cid, kind, size } ) ->
                            { cid = cid
                            , kind = kind
                            , name = name
                            , size = size
                            }
                        )
            )
