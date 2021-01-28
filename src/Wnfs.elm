module Wnfs exposing
    ( publish
    , mkdir, mv, rm, write, writeUtf8
    , exists, ls, read, readUtf8
    , add, cat
    , Base(..), Attributes, Artifact(..), Kind(..), Entry
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


{-| Kind of `Entry`.
-}
type Kind
    = Directory
    | File


{-| Application permissions.
-}
type alias AppPermissions =
    { creator : String
    , name : String
    }


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
    { context = context
    , tag = tag
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
publish : { tag : String } -> Request
publish { tag } =
    { context = context
    , tag = tag
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


makeRequest : Method -> Base -> List String -> String -> List Json.Value -> Request
makeRequest method base segments tag arguments =
    { context = context
    , tag = tag
    , method = methodToString method
    , arguments = Json.string (buildPath base segments) :: arguments
    }


wnfs : Method -> Base -> Attributes -> Request
wnfs method base { path, tag } =
    makeRequest method base path tag []


wnfsWithBytes : Method -> Base -> Attributes -> Bytes -> Request
wnfsWithBytes method base { path, tag } bytes =
    makeRequest method base path tag [ encodeBytes bytes ]



-- ㊙️  ⌘  PATH


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
