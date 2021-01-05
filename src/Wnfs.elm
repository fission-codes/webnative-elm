module Wnfs exposing (Artifact(..), Attributes, Base(..), Entry, Kind(..), add, cat, decodeResponse, exists, ls, mkdir, mv, publish, read, readUtf8, rm, write, writeUtf8)

import Bytes exposing (Bytes)
import Bytes.Encode
import Dict
import Json.Decode
import Json.Encode as Json
import Webnative exposing (AppPermissions, Request, Response)
import Wnfs.Internal exposing (..)



-- 🌳


type Artifact
    = NoArtifact
      --
    | Boolean Bool
    | CID String
    | DirectoryContent (List Entry)
    | FileContent Bytes
    | Utf8Content String


type Base
    = AppData AppPermissions
    | Private
    | Public


type Kind
    = Directory
    | File


type alias Attributes =
    { path : List String
    , tag : String
    }


type alias Entry =
    { cid : String
    , name : String
    , kind : Kind
    , size : Int
    }



-- 📣


add =
    write


cat =
    read


exists : Base -> Attributes -> Request
exists =
    wnfs Exists


ls : Base -> Attributes -> Request
ls =
    wnfs Ls


mkdir : Base -> Attributes -> Request
mkdir =
    wnfs Mkdir


mv : Base -> { from : List String, to : List String, tag : String } -> Request
mv base { from, to, tag } =
    { tag = tag
    , method = methodToString Mv
    , arguments =
        [ Json.string (buildPath base from)
        , Json.string (buildPath base to)
        ]
    }


publish : Request
publish =
    { tag = ""
    , method = methodToString Publish
    , arguments = []
    }


read : Base -> Attributes -> Request
read =
    wnfs Read


readUtf8 : Base -> Attributes -> Request
readUtf8 =
    wnfs ReadUtf8


rm : Base -> Attributes -> Request
rm =
    wnfs Rm


write : Base -> Attributes -> Bytes -> Request
write a b c =
    wnfsWithBytes Write a b c


writeUtf8 : Base -> Attributes -> String -> Request
writeUtf8 a b c =
    c
        |> Bytes.Encode.string
        |> Bytes.Encode.encode
        |> wnfsWithBytes Write a b



-- 📰


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
