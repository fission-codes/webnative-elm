module Webnative.Error exposing (Error(..), error)

{-| Webnative errors.

@docs Error, error

-}


{-| Possible Webnative errors.
-}
type Error
    = DecodingError String
    | InvalidMethod String
    | InsecureContext
    | JavascriptError String
    | TagParsingError String
    | UnsupportedBrowser


{-| Error message.
-}
error : Error -> String
error err =
    case err of
        DecodingError context ->
            "Couldn't decode webnative response: " ++ context

        InsecureContext ->
            "Webnative can't be used in a insecure browser context"

        InvalidMethod method ->
            "Invalid method: " ++ method

        JavascriptError string ->
            "Webnative.js error: " ++ string

        TagParsingError string ->
            "Couldn't parse tag: " ++ string

        UnsupportedBrowser ->
            "Webnative is not supported in this browser"
