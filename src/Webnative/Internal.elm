module Webnative.Internal exposing (..)

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
