module Webnative.Internal exposing (..)

-- METHOD


type Method
    = Initialise
    | Leave
    | LoadFileSystem
    | RedirectToLobby


methodFromString : String -> Maybe Method
methodFromString string =
    case string of
        "initialise" ->
            Just Initialise

        "leave" ->
            Just Leave

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

        Leave ->
            "leave"

        LoadFileSystem ->
            "loadFileSystem"

        RedirectToLobby ->
            "redirectToLobby"
