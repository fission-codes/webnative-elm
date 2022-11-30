module Webnative exposing (..)

import Json.Decode
import Json.Encode as Json
import Webnative.Configuration as Configuration exposing (Configuration)
import Webnative.FileSystem as FileSystem exposing (FileSystem)
import Webnative.Internal exposing (callTaskPort)
import Webnative.Program as Program exposing (Program)
import Webnative.Session as Session exposing (Session)
import Webnative.Task as Webnative



-- 🚀


program : Configuration -> Webnative.Task { program : Program, session : Maybe Session }
program =
    callTaskPort
        { function = "program"
        , valueDecoder =
            Json.Decode.map2
                (\p s -> { program = p, session = s })
                Program.decoder
                (Json.Decode.maybe Session.decoder)
        , argsEncoder =
            Configuration.encode
        }



-- 💾


loadFileSystem : { username : String } -> Webnative.Task FileSystem
loadFileSystem =
    callTaskPort
        { function = "loadFileSystem"
        , valueDecoder = FileSystem.decoder
        , argsEncoder = \{ username } -> Json.string username
        }


loadRootFileSystem : { username : String } -> Webnative.Task FileSystem
loadRootFileSystem =
    callTaskPort
        { function = "loadRootFileSystem"
        , valueDecoder = FileSystem.decoder
        , argsEncoder = \{ username } -> Json.string username
        }



-- 🛠


{-| Alias for `Webnative.Task.attempt`.
-}
attemptTask =
    Webnative.attempt
