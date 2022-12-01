module Webnative.Capabilities exposing (collect, request, session)

import Json.Decode
import TaskPort
import Webnative.Internal exposing (callTaskPort)
import Webnative.Program as Program exposing (Program)
import Webnative.Session as Session exposing (Session)
import Webnative.Task exposing (Task)



-- 🛠


collect : Program -> Task { username : Maybe String }
collect =
    callTaskPort
        { function = "capabilities.collect"
        , valueDecoder =
            Json.Decode.map
                (\u -> { username = u })
                (Json.Decode.maybe Json.Decode.string)
        , argsEncoder =
            Program.ref
        }


request : Program -> Task ()
request =
    callTaskPort
        { function = "capabilities.request"
        , valueDecoder = TaskPort.ignoreValue
        , argsEncoder = Program.ref
        }


session : Program -> Task (Maybe Session)
session =
    callTaskPort
        { function = "capabilities.session"
        , valueDecoder = Json.Decode.maybe Session.decoder
        , argsEncoder = Program.ref
        }
