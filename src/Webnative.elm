module Webnative exposing
    ( init, InitOptions, initWithOptions, initialise, initialize
    , decodeResponse, DecodedResponse(..), Artifact(..), NoArtifact(..), Request, Response, Error(..), error
    , redirectToLobby, RedirectTo(..), AppPermissions, FileSystemPermissions, Permissions
    , isAuthenticated, State(..), AuthSucceededState, AuthCancelledState, ContinuationState
    , loadFileSystem
    )

{-| Interface for [webnative](https://github.com/fission-suite/webnative#readme).

1.  [Getting Started](#getting-started)
2.  [Ports](#ports)
3.  [Authorisation](#authorisation)
4.  [Authentication](#authentication)
5.  [Filesystem](#filesystem)
6.  [Miscellaneous](#miscellaneous)


# Getting Started

@docs init, InitOptions, initWithOptions, initialise, initialize


# Ports

Data flowing through the ports. See `🚀` in the `decodeResponse` example on how to handle the result from `init`.

@docs decodeResponse, DecodedResponse, Artifact, NoArtifact, Request, Response, Error, error


# Authorisation

@docs redirectToLobby, RedirectTo, AppPermissions, FileSystemPermissions, Permissions


# Authentication

@docs isAuthenticated, State, AuthSucceededState, AuthCancelledState, ContinuationState


# Filesystem

@docs loadFileSystem

-}

import Bytes exposing (Bytes)
import Dict
import Json.Decode exposing (Decoder)
import Json.Encode as Json
import Maybe.Extra as Maybe
import Url exposing (Url)
import Webnative.Internal as Webnative exposing (..)
import Wnfs exposing (Artifact(..), Kind(..))
import Wnfs.Internal as Wnfs exposing (..)



-- 🌳


{-| Artifact we receive in the response.
-}
type Artifact
    = Initialisation State
    | NoArtifact NoArtifact


{-| Not really artifacts, but kind of.
Part of the `Artifact` type.
-}
type NoArtifact
    = LoadedFileSystemManually
    | RedirectingToLobby


{-| Request, or response, context.
-}
type DecodedResponse tag
    = Webnative Artifact
    | WebnativeError Error
    | Wnfs tag Wnfs.Artifact
    | WnfsError Wnfs.Error


{-| Possible errors.
-}
type Error
    = DecodingError String
    | InvalidMethod String
    | InsecureContext
    | JavascriptError String
    | UnsupportedBrowser


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
    , loadFileSystem : Bool
    }


{-| Default `InitOptions`.
-}
defaultInitOptions : InitOptions
defaultInitOptions =
    { autoRemoveUrlParams = True
    , loadFileSystem = True
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

See the [README](../latest/) for an example.

-}
init : Permissions -> Request
init =
    initWithOptions defaultInitOptions


{-| Initialise webnative, with options.
-}
initWithOptions : InitOptions -> Permissions -> Request
initWithOptions options permissions =
    { context = context
    , tag = ""
    , method = Webnative.methodToString Initialise
    , arguments =
        [ Json.object
            [ ( "autoRemoveUrlParams"
              , Json.bool options.autoRemoveUrlParams
              )
            , ( "loadFileSystem"
              , Json.bool options.loadFileSystem
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
loadFileSystem : Permissions -> Request
loadFileSystem permissions =
    { context = context
    , tag = ""
    , method = Webnative.methodToString LoadFileSystem
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
    { context = context
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


{-| Decode the result, the `Response`, from our `Request`.
Connect this up with `webnativeResponse` subscription port.

    subscriptions =
        Ports.webnativeResponse GotWebnativeResponse

And then in `update` use this function.

    GotWebnativeResponse response ->
      case Webnative.decodeResponse tagFromString response of
        -----------------------------------------
        -- 🚀
        -----------------------------------------
        Webnative ( Initialisation state ) ->
          if Webnative.isAuthenticated state then
            loadUserData
          else
            welcome

        -----------------------------------------
        -- 💾
        -----------------------------------------
        Wnfs ReadHelloTxt ( Utf8Content helloContents ) ->
          -- Do something with content from hello.txt

        Wnfs Mutation _ ->
          ( model
          , { tag = PointerUpdated }
              |> Wnfs.publish
              |> Ports.webnativeRequest
          )

        -----------------------------------------
        -- 🥵
        -----------------------------------------
        -- Do something with the errors,
        -- here we cast them to strings
        WebnativeError err -> Webnative.error err
        WnfsError err -> Wnfs.error err

See the [README](../latest/) for the full example.

-}
decodeResponse :
    (String -> Result String tag)
    -> Response
    -> DecodedResponse tag
decodeResponse tagParser response =
    case ( response.error, response.context ) of
        -----------------------------------------
        -- Errors
        -----------------------------------------
        ( Just "INSECURE_CONTEXT", _ ) ->
            WebnativeError InsecureContext

        ( Just "UNSUPPORTED_BROWSER", _ ) ->
            WebnativeError UnsupportedBrowser

        ( Just err, "WEBNATIVE" ) ->
            WebnativeError (JavascriptError err)

        ( Just err, "WNFS" ) ->
            WnfsError (Wnfs.JavascriptError err)

        -----------------------------------------
        -- Webnative
        -----------------------------------------
        ( Nothing, "WEBNATIVE" ) ->
            case decodeWebnativeResponse response of
                Ok artifact ->
                    Webnative artifact

                Err err ->
                    WebnativeError err

        -----------------------------------------
        -- WNFS
        -----------------------------------------
        ( Nothing, "WNFS" ) ->
            case decodeWnfsResponse tagParser response of
                Ok ( tag, artifact ) ->
                    Wnfs tag artifact

                Err err ->
                    WnfsError err

        -- Invalid context
        ( _, _ ) ->
            "Invalid content"
                |> JavascriptError
                |> WebnativeError


{-| `Error` message.
-}
error : Error -> String
error err =
    case err of
        DecodingError ctx ->
            "Couldn't decode webnative response: " ++ ctx

        InsecureContext ->
            "Webnative can't be used in a insecure browser context"

        InvalidMethod method ->
            "Invalid method: " ++ method

        JavascriptError string ->
            "Webnative.js error: " ++ string

        UnsupportedBrowser ->
            "Webnative is not supported in this browser"



-- ㊙️


context : String
context =
    "WEBNATIVE"


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


decodeWebnativeResponse : Response -> Result Error Artifact
decodeWebnativeResponse response =
    case Webnative.methodFromString response.method of
        Nothing ->
            Err (InvalidMethod response.method)

        Just method ->
            response.data
                |> Json.Decode.decodeValue
                    (case method of
                        Initialise ->
                            Json.Decode.map Initialisation stateDecoder

                        LoadFileSystem ->
                            Json.Decode.succeed (NoArtifact LoadedFileSystemManually)

                        RedirectToLobby ->
                            Json.Decode.succeed (NoArtifact RedirectingToLobby)
                    )
                |> Result.mapError
                    (Json.Decode.errorToString >> DecodingError)


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


decodeWnfsResponse : (String -> Result String tag) -> Response -> Result Wnfs.Error ( tag, Wnfs.Artifact )
decodeWnfsResponse tagParser response =
    case Wnfs.methodFromString response.method of
        Nothing ->
            Err (Wnfs.InvalidMethod response.method)

        Just method ->
            response.data
                |> Json.Decode.decodeValue
                    (case method of
                        Exists ->
                            Json.Decode.map Boolean Json.Decode.bool

                        Ls ->
                            Json.Decode.map DirectoryContent directoryContentDecoder

                        Mkdir ->
                            Json.Decode.succeed Wnfs.NoArtifact

                        Mv ->
                            Json.Decode.succeed Wnfs.NoArtifact

                        Publish ->
                            Json.Decode.map CID cidDecoder

                        Read ->
                            Json.Decode.map FileContent fileContentDecoder

                        ReadUtf8 ->
                            Json.Decode.map Utf8Content utf8ContentDecoder

                        Rm ->
                            Json.Decode.succeed Wnfs.NoArtifact

                        Write ->
                            Json.Decode.succeed Wnfs.NoArtifact
                    )
                |> Result.mapError
                    (Json.Decode.errorToString >> Wnfs.DecodingError)
                |> Result.andThen
                    (\artifact ->
                        response.tag
                            |> tagParser
                            |> Result.map (\t -> ( t, artifact ))
                            |> Result.mapError Wnfs.TagParsingError
                    )


directoryContentDecoder : Json.Decode.Decoder (List Wnfs.Entry)
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
