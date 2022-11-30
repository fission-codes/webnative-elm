module Webnative.Internal exposing (..)

import Bytes exposing (Bytes)
import Bytes.Decode
import Bytes.Decode.Extra
import Bytes.Encode
import Bytes.Encode.Extra
import Json.Decode exposing (Decoder, Value)
import Json.Encode as Json
import String.UTF8 as UTF8
import Task exposing (Task)
import TaskPort
import Webnative.Error as Error exposing (Error)



-- 🏔


qualifiedTaskPortFunctionName : TaskPort.FunctionName -> TaskPort.QualifiedName
qualifiedTaskPortFunctionName =
    TaskPort.inNamespace "fission-codes/webnative" "8.0.0"



-- BYTES


encodeBytes : Bytes -> Json.Value
encodeBytes bytes =
    bytes
        |> Bytes.Decode.decode
            (bytes
                |> Bytes.width
                |> Bytes.Decode.Extra.byteValues
            )
        |> Maybe.withDefault []
        |> Json.list Json.int


toBytes : List Int -> Bytes
toBytes list =
    list
        |> Bytes.Encode.Extra.byteValues
        |> Bytes.Encode.encode



-- FILE SYSTEM


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
    Json.Decode.int
        |> Json.Decode.list
        |> Json.Decode.andThen
            (\list ->
                case UTF8.toString list of
                    Ok string ->
                        Json.Decode.succeed string

                    Err err ->
                        Json.Decode.fail err
            )



-- TASKPORTS


callTaskPort :
    { function : String
    , valueDecoder : Decoder value
    , argsEncoder : args -> Value
    }
    -> args
    -> Task Error value
callTaskPort opts args =
    args
        |> TaskPort.callNS
            { function = qualifiedTaskPortFunctionName opts.function
            , valueDecoder = Json.Decode.oneOf [ taskPortResultDecoder opts.valueDecoder, opts.valueDecoder ]
            , argsEncoder = opts.argsEncoder
            }
        |> Task.mapError Error.fromTaskPort


callTaskPortWithoutArgs :
    { function : String
    , valueDecoder : Decoder value
    }
    -> Task Error value
callTaskPortWithoutArgs opts =
    { function = qualifiedTaskPortFunctionName opts.function
    , valueDecoder = Json.Decode.oneOf [ taskPortResultDecoder opts.valueDecoder, opts.valueDecoder ]
    }
        |> TaskPort.callNoArgsNS
        |> Task.mapError Error.fromTaskPort


taskPortResultDecoder : Decoder a -> Decoder a
taskPortResultDecoder valueDecoder =
    Json.Decode.oneOf
        [ Json.Decode.field "ok" valueDecoder
        , Json.Decode.andThen Json.Decode.fail (Json.Decode.field "error" Json.Decode.string)
        ]
