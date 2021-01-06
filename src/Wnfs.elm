module Wnfs exposing
    ( publish
    , mkdir, mv, rm, write, writeUtf8
    , exists, ls, read, readUtf8
    , add, cat
    , decodeResponse
    , Base(..), Attributes, Artifact(..)
    , Entry, Kind(..)
    )

{-| Interact with your filesystem.


# Actions

@docs publish


## Mutations

@docs mkdir, mv, rm, write, writeUtf8


## Queries

@docs exists, ls, read, readUtf8


## Aliases

@docs add, cat


# Ports

@docs decodeResponse


# Types

@docs Base, Attributes, Artifact


## Lists

@docs Entry, Kind

-}

import Bytes exposing (Bytes)
import Bytes.Encode
import Dict
import Json.Decode
import Json.Encode as Json
import Webnative exposing (AppPermissions, Request, Response)
import Wnfs.Internal exposing (..)



-- 🌳


{-| Artifact we receive in the response.
-}
type Artifact
    = NoArtifact
      --
    | Boolean Bool
    | CID String
    | DirectoryContent (List Entry)
    | FileContent Bytes
    | Utf8Content String


{-| Base of the WNFS action.
-}
type Base
    = AppData AppPermissions
    | Private
    | Public


{-| Kind of `Entry`.
-}
type Kind
    = Directory
    | File


{-| WNFS action attributes.
-}
type alias Attributes =
    { path : List String
    , tag : String
    }


{-| Directory `Entry`.
-}
type alias Entry =
    { cid : String
    , name : String
    , kind : Kind
    , size : Int
    }



-- 📣


{-| Alias for `write`.
-}
add : Base -> Attributes -> Bytes -> Request
add =
    write


{-| Alias for `read`.
-}
cat : Base -> Attributes -> Request
cat =
    read


{-| Check if something exists in the filesystem.
-}
exists : Base -> Attributes -> Request
exists =
    wnfs Exists


{-| List a directory.
-}
ls : Base -> Attributes -> Request
ls =
    wnfs Ls


{-| Create a directory.
-}
mkdir : Base -> Attributes -> Request
mkdir =
    wnfs Mkdir


{-| Move.
-}
mv : Base -> { from : List String, to : List String, tag : String } -> Request
mv base { from, to, tag } =
    { tag = tag
    , method = methodToString Mv
    , arguments =
        [ Json.string (buildPath base from)
        , Json.string (buildPath base to)
        ]
    }


{-| Publish your changes to your filesystem.
**📢 You should run this after doing mutations.**
See [README](../) examples for more info.
-}
publish : Request
publish =
    { tag = ""
    , method = methodToString Publish
    , arguments = []
    }


{-| Read something from the filesystem in the form of `Bytes`.
-}
read : Base -> Attributes -> Request
read =
    wnfs Read


{-| Read something from the filesystem in the form of a `String`.
-}
readUtf8 : Base -> Attributes -> Request
readUtf8 =
    wnfs ReadUtf8


{-| Remove.
-}
rm : Base -> Attributes -> Request
rm =
    wnfs Rm


{-| Write to the filesystem using `Bytes`.
-}
write : Base -> Attributes -> Bytes -> Request
write a b c =
    wnfsWithBytes Write a b c


{-| Write to the filesystem using a `String`.
-}
writeUtf8 : Base -> Attributes -> String -> Request
writeUtf8 a b c =
    c
        |> Bytes.Encode.string
        |> Bytes.Encode.encode
        |> wnfsWithBytes Write a b



-- 📰


{-| Function to be used to decode the response from webnative we got through our port.

    GotWnfsResponse response ->
        case Wnfs.decodeResponse tagFromString response of
            Ok ( ReadHelloTxt, Wnfs.Utf8Content helloContents ) ->
                -- Do something with content from hello.txt

            Ok ( Mutation, _ ) ->
                ( model
                , Ports.wnfsRequest Wnfs.publish
                )

            Err errString ->
                -- Decoding, or tag parse, error.

See the [README](../) for the full example.

-}
decodeResponse : (String -> Result String tag) -> Response -> Result String ( tag, Artifact )
decodeResponse tagParser response =
    case methodFromString response.method of
        Nothing ->
            Err (error InvalidMethod response.method)

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
                    (Json.Decode.errorToString >> error DecodingError)
                |> Result.andThen
                    (\artifact ->
                        response.tag
                            |> tagParser
                            |> Result.map (\t -> ( t, artifact ))
                    )



-- ㊙️


type Error
    = DecodingError
    | InvalidMethod


error : Error -> String -> String
error err context =
    case err of
        DecodingError ->
            "Couldn't decode WNFS response: " ++ context

        InvalidMethod ->
            "Invalid method: " ++ context


makeRequest : Method -> Base -> List String -> String -> List Json.Value -> Request
makeRequest method base segments tag arguments =
    { tag = tag
    , method = methodToString method
    , arguments = Json.string (buildPath base segments) :: arguments
    }


wnfs : Method -> Base -> Attributes -> Request
wnfs method base { path, tag } =
    makeRequest method base path tag []


wnfsWithBytes : Method -> Base -> Attributes -> Bytes -> Request
wnfsWithBytes method base { path, tag } bytes =
    makeRequest method base path tag [ encodeBytes bytes ]



-- ㊙️  ~  PATH


buildPath : Base -> List String -> String
buildPath base segments =
    String.append
        (case base of
            AppData { creator, name } ->
                "/private/Apps/" ++ creator ++ "/" ++ name ++ "/"

            Private ->
                "/private/"

            Public ->
                "/public/"
        )
        (String.join
            "/"
            segments
        )



-- ㊙️  ~  ENTRIES


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
