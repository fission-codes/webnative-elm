module Webnative.Program exposing (Program, decoder)

import Json.Decode exposing (Decoder)



-- 🌳


type Program
    = ProgramReference String



-- 🛠


decoder : Decoder Program
decoder =
    Json.Decode.map ProgramReference Json.Decode.string
