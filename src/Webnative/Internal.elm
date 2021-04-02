module Webnative.Internal exposing (..)

-- METHOD


type Method
    = Initialise
    | LoadFileSystem
    | RedirectToLobby


methodFromString : String -> Maybe Method
methodFromString string =
    case string of
        "initialise" ->
            Just Initialise

        "loadFileSystem" ->
            Just LoadFileSystem

        "redirectToLobby" ->
            Just RedirectToLobby

        _ ->
            Nothing


methodToString : Method -> String
methodToString method =
    case method of
        Initialise ->
            "initialise"

        LoadFileSystem ->
            "loadFileSystem"

        RedirectToLobby ->
            "redirectToLobby"
