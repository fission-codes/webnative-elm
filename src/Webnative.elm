module Webnative exposing (Foundation, program, attemptTask)

{-|

@docs Foundation, program, attemptTask

-}

import Json.Decode
import Webnative.Configuration as Configuration exposing (Configuration)
import Webnative.Error as Webnative
import Webnative.FileSystem as FileSystem exposing (FileSystem)
import Webnative.Internal exposing (callTaskPort)
import Webnative.Program as Program exposing (Program)
import Webnative.Session as Session exposing (Session)
import Webnative.Task as Webnative



-- 🚀


{-| -}
type alias Foundation =
    { fileSystem : Maybe FileSystem
    , program : Program
    , session : Maybe Session
    }


{-| -}
program : Configuration -> Webnative.Task Foundation
program =
    callTaskPort
        { function = "program"
        , valueDecoder =
            Json.Decode.map3
                (\f p s -> { fileSystem = f, program = p, session = s })
                (Json.Decode.field "fs" <| Json.Decode.maybe FileSystem.decoder)
                (Json.Decode.field "program" Program.decoder)
                (Json.Decode.field "session" <| Json.Decode.maybe Session.decoder)
        , argsEncoder =
            Configuration.encode
        }



-- 🛠


{-| Alias for `Webnative.Task.attempt`.
-}
attemptTask : { error : Webnative.Error -> msg, ok : value -> msg } -> Webnative.Task value -> Cmd msg
attemptTask =
    Webnative.attempt
