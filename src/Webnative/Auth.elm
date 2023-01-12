module Webnative.Auth exposing (isUsernameAvailable, isUsernameValid, register, session, sessionWithFileSystem)

{-|

@docs isUsernameAvailable, isUsernameValid, register, session, sessionWithFileSystem

-}

import Json.Decode
import Json.Encode as Json
import Maybe.Extra as Maybe
import Task
import Webnative.FileSystem as FileSystem exposing (FileSystem)
import Webnative.Internal exposing (callTaskPort)
import Webnative.Program as Program exposing (Program)
import Webnative.Session as Session exposing (Session)
import Webnative.Task exposing (Task)



-- 🛠


{-| -}
isUsernameAvailable : Program -> String -> Task Bool
isUsernameAvailable program =
    callTaskPort
        { function = "auth_isUsernameAvailable"
        , valueDecoder = Json.Decode.bool
        , argsEncoder = Json.string >> Program.withRef program
        }


{-| -}
isUsernameValid : Program -> String -> Task Bool
isUsernameValid program =
    callTaskPort
        { function = "auth_isUsernameValid"
        , valueDecoder = Json.Decode.bool
        , argsEncoder = Json.string >> Program.withRef program
        }


{-| -}
register : Program -> { email : Maybe String, username : String } -> Task { success : Bool }
register program =
    callTaskPort
        { function = "auth_register"
        , valueDecoder =
            Json.Decode.map
                (\s -> { success = s })
                (Json.Decode.field "success" Json.Decode.bool)
        , argsEncoder =
            \{ email, username } ->
                [ ( "email", Maybe.unwrap Json.null Json.string email )
                , ( "username", Json.string username )
                ]
                    |> Json.object
                    |> Program.withRef program
        }


{-| -}
session : Program -> Task (Maybe Session)
session =
    callTaskPort
        { function = "auth_session"
        , valueDecoder = Json.Decode.maybe Session.decoder
        , argsEncoder = Program.ref
        }


{-| -}
sessionWithFileSystem : Program -> Task (Maybe { fileSystem : FileSystem, session : Session })
sessionWithFileSystem program =
    Task.andThen
        (\maybe ->
            case maybe of
                Just ses ->
                    { username = ses.username }
                        |> FileSystem.load program
                        |> Task.map (\fs -> Just { fileSystem = fs, session = ses })

                Nothing ->
                    Task.succeed Nothing
        )
        (session program)
