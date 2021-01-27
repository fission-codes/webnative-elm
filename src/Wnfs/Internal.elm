module Wnfs.Internal exposing (..)

import Bytes exposing (Bytes)
import Bytes.Decode
import Bytes.Decode.Extra
import Bytes.Encode
import Bytes.Encode.Extra
import Json.Decode
import Json.Encode
import String.UTF8 as UTF8



-- BYTES


encodeBytes : Bytes -> Json.Encode.Value
encodeBytes bytes =
    bytes
        |> Bytes.Decode.decode
            (bytes
                |> Bytes.width
                |> Bytes.Decode.Extra.byteValues
            )
        |> Maybe.withDefault []
        |> Json.Encode.list Json.Encode.int


toBytes : List Int -> Bytes
toBytes list =
    list
        |> Bytes.Encode.Extra.byteValues
        |> Bytes.Encode.encode



-- JSON


cidDecoder : Json.Decode.Decoder String
cidDecoder =
    Json.Decode.string


fileContentDecoder : Json.Decode.Decoder Bytes
fileContentDecoder =
    Json.Decode.int
        |> Json.Decode.list
        |> Json.Decode.map toBytes


utf8ContentDecoder : Json.Decode.Decoder String
utf8ContentDecoder =
    Json.Decode.oneOf
        [ Json.Decode.string
        , Json.Decode.int
            |> Json.Decode.list
            |> Json.Decode.andThen
                (\list ->
                    case UTF8.toString list of
                        Ok string ->
                            Json.Decode.succeed string

                        Err err ->
                            Json.Decode.fail err
                )
        ]



-- METHOD


type Method
    = Exists
    | Ls
    | Mkdir
    | Mv
    | Publish
    | Read
    | ReadUtf8
    | Rm
    | Write


methodFromString : String -> Maybe Method
methodFromString string =
    case string of
        "exists" ->
            Just Exists

        "ls" ->
            Just Ls

        "mkdir" ->
            Just Mkdir

        "mv" ->
            Just Mv

        "publish" ->
            Just Publish

        "read" ->
            Just Read

        "read_utf8" ->
            Just ReadUtf8

        "rm" ->
            Just Rm

        "write" ->
            Just Write

        _ ->
            Nothing


methodToString : Method -> String
methodToString method =
    case method of
        Exists ->
            "exists"

        Ls ->
            "ls"

        Mkdir ->
            "mkdir"

        Mv ->
            "mv"

        Publish ->
            "publish"

        Read ->
            "read"

        ReadUtf8 ->
            "read_utf8"

        Rm ->
            "rm"

        Write ->
            "write"
