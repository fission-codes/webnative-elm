module Webnative.Capabilities exposing (collect, request, session)

import Json.Decode
import TaskPort
import Webnative.Internal exposing (callTaskPort)
import Webnative.Program as Program exposing (Program)
import Webnative.Session as Session exposing (Session)
import Webnative.Task exposing (Task)



-- 🛠


collect : Program -> Task { username : Maybe String }
collect program =
    callTaskPort
        { function = "capabilities.collect"
        , valueDecoder =
            Json.Decode.map
                (\u -> { username = u })
                (Json.Decode.maybe Json.Decode.string)
        , argsEncoder =
            identity
        }
        (Program.ref program)


request : Program -> Task ()
request program =
    callTaskPort
        { function = "capabilities.request"
        , valueDecoder = TaskPort.ignoreValue
        , argsEncoder = identity
        }
        (Program.ref program)


session : Program -> Task (Maybe Session)
session program =
    callTaskPort
        { function = "capabilities.session"
        , valueDecoder = Json.Decode.maybe Session.decoder
        , argsEncoder = identity
        }
        (Program.ref program)
