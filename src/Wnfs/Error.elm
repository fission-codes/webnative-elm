module Wnfs.Error exposing (Error(..), error)

{-| WNFS errors.

@docs Error, error

-}


{-| Possible WNFS errors.
-}
type Error
    = DecodingError String
    | InvalidMethod String
    | TagParsingError String
    | JavascriptError String


{-| Error message.
-}
error : Error -> String
error err =
    case err of
        DecodingError context ->
            "Couldn't decode WNFS response: " ++ context

        InvalidMethod method ->
            "Invalid method: " ++ method

        JavascriptError string ->
            "Wnfs.js error: " ++ string

        TagParsingError string ->
            "Couldn't parse tag: " ++ string
