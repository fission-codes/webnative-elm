module Webnative.Configuration exposing (Configuration, encode)

import Json.Encode as Json
import Webnative.Namespace as Namespace exposing (Namespace)



-- 🌳


type alias Configuration =
    { namespace : Namespace
    }



-- 🛠


encode : Configuration -> Value
encode { namespace } =
    Json.object
        [ ( "namespace", Json.string (Namespace.toString namespace) )
        ]
