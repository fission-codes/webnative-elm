module Wnfs exposing
    ( publish
    , mkdir, mv, rm, write, writeUtf8
    , exists, ls, read, readUtf8
    , add, cat
    , Base(..), Attributes, Artifact(..), Entry
    , Error(..), error
    )

{-| Interact with your webnative [filesystem](https://guide.fission.codes/developers/webnative#file-system).


# Actions

@docs publish


## Mutations

@docs mkdir, mv, rm, write, writeUtf8


## Queries

@docs exists, ls, read, readUtf8


## Aliases

@docs add, cat


# Requests & Responses

@docs Base, Attributes, Artifact, Kind, Entry


# Errors

@docs Error, error

-}

import Bytes exposing (Bytes)
import Bytes.Encode
import Json.Decode
import Json.Encode as Json
import Webnative.Path as Path exposing (Directory, File, Kind(..), Path)
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


{-| Possible errors.
-}
type Error
    = DecodingError String
    | InvalidMethod String
    | TagParsingError String
    | JavascriptError String


{-| Application permissions.
-}
type alias AppPermissions =
    { creator : String
    , name : String
    }


{-| WNFS action attributes.
-}
type alias Attributes pathKind =
    { path : Path pathKind
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



-- 📣  DIRECTORIES


{-| List a directory.
-}
ls : Base -> Attributes Directory -> Request
ls =
    wnfs Ls


{-| Create a directory.
-}
mkdir : Base -> Attributes Directory -> Request
mkdir =
    wnfs Mkdir



-- 📣  FILES


{-| Alias for `write`.
-}
add : Base -> Attributes File -> Bytes -> Request
add =
    write


{-| Alias for `read`.
-}
cat : Base -> Attributes File -> Request
cat =
    read


{-| Read a file from the filesystem in the form of `Bytes`.
-}
read : Base -> Attributes File -> Request
read =
    wnfs Read


{-| Read a file from the filesystem in the form of a `String`.
-}
readUtf8 : Base -> Attributes File -> Request
readUtf8 =
    wnfs ReadUtf8


{-| Write to a file using `Bytes`.
-}
write : Base -> Attributes File -> Bytes -> Request
write a b c =
    wnfsWithBytes Write a b c


{-| Write to a file using a `String`.
-}
writeUtf8 : Base -> Attributes File -> String -> Request
writeUtf8 a b c =
    c
        |> Bytes.Encode.string
        |> Bytes.Encode.encode
        |> wnfsWithBytes Write a b



-- 📣  DIRECTORIES & FILES


{-| Check if something exists.
-}
exists : Base -> Attributes a -> Request
exists =
    wnfs Exists


{-| Move something from one location to another.
-}
mv : Base -> { from : Path t, to : Path t, tag : String } -> Request
mv base { from, to, tag } =
    { context = context
    , tag = tag
    , method = methodToString Mv
    , arguments =
        [ encodePath base from
        , encodePath base to
        ]
    }


{-| Remove something from the filesystem.
-}
rm : Base -> Attributes a -> Request
rm =
    wnfs Rm



-- 📣


{-| Publish your changes to your filesystem.
**📢 You should run this after doing mutations.**
See [README](../latest/) examples for more info.
-}
publish : { tag : String } -> Request
publish { tag } =
    { context = context
    , tag = tag
    , method = methodToString Publish
    , arguments = []
    }



-- 🛠


{-| `Error` message.
-}
error : Error -> String
error err =
    case err of
        DecodingError ctx ->
            "Couldn't decode WNFS response: " ++ ctx

        InvalidMethod method ->
            "Invalid method: " ++ method

        JavascriptError string ->
            "Wnfs.js error: " ++ string

        TagParsingError string ->
            "Couldn't parse tag: " ++ string



-- ㊙️


context : String
context =
    "WNFS"


makeRequest : Method -> Base -> Path k -> String -> List Json.Value -> Request
makeRequest method base path tag arguments =
    { context = context
    , tag = tag
    , method = methodToString method
    , arguments = encodePath base path :: arguments
    }


wnfs : Method -> Base -> Attributes k -> Request
wnfs method base { path, tag } =
    makeRequest method base path tag []


wnfsWithBytes : Method -> Base -> Attributes k -> Bytes -> Request
wnfsWithBytes method base { path, tag } bytes =
    makeRequest method base path tag [ encodeBytes bytes ]



-- ㊙️  ⌘  PATH


encodePath : Base -> Path k -> Json.Value
encodePath base path =
    path
        |> Path.unwrap
        |> List.append
            (case base of
                AppData { creator, name } ->
                    [ "private", "Apps", creator, name ]

                Private ->
                    [ "private" ]

                Public ->
                    [ "public" ]
            )
        |> Path.directory
        |> Path.toTypescriptFormat
