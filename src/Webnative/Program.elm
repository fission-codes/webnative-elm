module Webnative.Program exposing (Program, decoder, encode, withRef)

import Json.Decode exposing (Decoder)
import Json.Encode as Json



-- 🌳


type Program
    = ProgramReference String



-- 🛠


decoder : Decoder Program
decoder =
    Json.Decode.map ProgramReference Json.Decode.string


encode : Program -> Json.Value
encode (ProgramReference ref) =
    Json.string ref


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
