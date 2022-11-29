module Webnative.Error exposing (..)

import Json.Decode exposing (Decoder)



-- 🌳


type Error
    = InsecureContext
    | JavascriptError String
    | UnsupportedBrowser



-- 🛠


decoder : Decoder Error
decoder =
    Json.Decode.map
        fromString
        Json.Decode.string


fromString : String -> Error
fromString string =
    case string of
        "INSECURE_CONTEXT" ->
            InsecureContext

        "UNSUPPORTED_BROWSER" ->
            UnsupportedBrowser

        _ ->
            JavascriptError string
