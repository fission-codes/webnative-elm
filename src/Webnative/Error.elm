module Webnative.Error exposing
    ( decoder, fromString, fromTaskPort
    , Error(..)
    )

{-|

@docs Error, decoder, fromString, fromTaskPort

-}

import Json.Decode exposing (Decoder)
import TaskPort



-- 🌳


{-| -}
type Error
    = InsecureContext
    | JavascriptError String
    | UnsupportedBrowser



-- 🛠


{-| -}
decoder : Decoder Error
decoder =
    Json.Decode.map
        fromString
        Json.Decode.string


{-| -}
fromString : String -> Error
fromString string =
    case string of
        "INSECURE_CONTEXT" ->
            InsecureContext

        "UNSUPPORTED_BROWSER" ->
            UnsupportedBrowser

        _ ->
            JavascriptError string


{-| -}
fromTaskPort : TaskPort.Error -> Error
fromTaskPort error =
    case error of
        TaskPort.InteropError interopError ->
            fromString (TaskPort.interopErrorToString interopError)

        TaskPort.JSError (TaskPort.ErrorValue value) ->
            value
                |> Json.Decode.decodeValue decoder
                |> Result.withDefault (fromString <| TaskPort.errorToString error)

        TaskPort.JSError _ ->
            fromString (TaskPort.errorToString error)
