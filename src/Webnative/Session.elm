module Webnative.Session exposing (Session, decoder)

import Json.Decode exposing (Decoder)



-- 🌳


type alias Session =
    { kind : String
    , username : String
    }



-- 🛠


decoder : Decoder Session
decoder =
    Json.Decode.map2
        Session
        (Json.Decode.field "type" Json.Decode.string)
        (Json.Decode.field "username" Json.Decode.string)
