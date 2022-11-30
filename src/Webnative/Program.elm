module Webnative.Program exposing (Program, decoder, encode, ref, withRef, withRefSplat)

import Json.Decode exposing (Decoder)
import Json.Encode as Json



-- 🌳


type Program
    = ProgramReference String



-- REFERENCE


ref : Program -> Json.Value
ref program =
    Json.object
        [ ( "programRef", encode program ) ]


withRef : Program -> Json.Value -> Json.Value
withRef program arg =
    Json.object
        [ ( "programRef", encode program )
        , ( "arg", arg )
        ]


withRefSplat : Program -> Json.Value -> Json.Value
withRefSplat program arg =
    Json.object
        [ ( "programRef", encode program )
        , ( "arg", arg )
        , ( "useSplat", Json.bool True )
        ]



-- 🛠


decoder : Decoder Program
decoder =
    Json.Decode.map ProgramReference Json.Decode.string


encode : Program -> Json.Value
encode (ProgramReference r) =
    Json.string r
