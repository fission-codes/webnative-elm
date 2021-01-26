module Webnative.Internal exposing (..)

-- ERRORS


type Error
    = DecodingError
    | InvalidMethod
    | InsecureContext
    | UnsupportedBrowser


error : Error -> String -> String
error err context =
    case err of
        DecodingError ->
            "Couldn't decode webnative response: " ++ context

        InsecureContext ->
            "Webnative can't be used in a insecure browser context"

        InvalidMethod ->
            "Invalid method: " ++ context

        UnsupportedBrowser ->
            "Webnative is not supported in this browser"



-- METHOD


type Method
    = Initialise
    | LoadFilesystem
    | RedirectToLobby


methodFromString : String -> Maybe Method
methodFromString string =
    case string of
        "initialise" ->
            Just Initialise

        "loadFilesystem" ->
            Just LoadFilesystem

        "redirectToLobby" ->
            Just RedirectToLobby

        _ ->
            Nothing


methodToString : Method -> String
methodToString method =
    case method of
        Initialise ->
            "initialise"

        LoadFilesystem ->
            "loadFilesystem"

        RedirectToLobby ->
            "redirectToLobby"
