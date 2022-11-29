module Webnative.Configuration exposing (Configuration, encode)

import Json.Encode exposing (Value)
import Webnative.Namespace as Namespace exposing (Namespace)



-- 🌳


type alias Configuration =
    { namespace : Namespace
    }



-- 🛠


encode : Configuration -> Value
encode { namespace } =
    Json.Encode.object
        [ ( "namespace", Json.Encode.string (Namespace.toString namespace) )
        ]
