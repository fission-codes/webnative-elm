module Webnative exposing (..)

import Webnative.Common exposing (callTaskPort)
import Webnative.Configuration as Configuration exposing (Configuration)
import Webnative.Program as Program exposing (Program)
import Webnative.Task as Webnative



-- 🚀


program : Configuration -> Webnative.Task Program
program =
    callTaskPort
        { function = "program"
        , valueDecoder = Program.decoder
        , argsEncoder = Configuration.encode
        }



-- 🛠


{-| Alias for `Webnative.Task.attempt`.
-}
attemptTask =
    Webnative.attempt
