module Webnative.Auth exposing (..)

import Json.Decode
import Json.Encode as Json
import Maybe.Extra as Maybe
import Webnative.Common exposing (callTaskPort)
import Webnative.Program as Program exposing (Program)
import Webnative.Task exposing (Task)



-- 🛠


register : Program -> { email : Maybe String, username : String } -> Task { success : Bool }
register program =
    callTaskPort
        { function = "auth.register"
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
