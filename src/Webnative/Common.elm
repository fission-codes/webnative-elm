module Webnative.Common exposing (..)

import Json.Decode exposing (Decoder, Value)
import Task exposing (Task)
import TaskPort
import Webnative.Error as Error exposing (Error)



-- 🛠


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
            { function = TaskPort.inNamespace "fission-codes/webnative" "8.0.0" opts.function
            , valueDecoder = Json.Decode.oneOf [ taskPortResultDecoder opts.valueDecoder, opts.valueDecoder ]
            , argsEncoder = opts.argsEncoder
            }
        |> Task.mapError
            (\error ->
                case error of
                    TaskPort.InteropError interopError ->
                        Error.fromString (TaskPort.interopErrorToString interopError)

                    TaskPort.JSError (TaskPort.ErrorObject string _) ->
                        Error.fromString string

                    TaskPort.JSError (TaskPort.ErrorValue value) ->
                        value
                            |> Json.Decode.decodeValue Error.decoder
                            |> Result.withDefault (Error.fromString <| TaskPort.errorToString error)
            )


taskPortResultDecoder valueDecoder =
    Json.Decode.oneOf
        [ Json.Decode.field "ok" valueDecoder
        , Json.Decode.andThen Json.Decode.fail (Json.Decode.field "error" Json.Decode.string)
        ]
