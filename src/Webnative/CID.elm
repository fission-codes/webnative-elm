module Webnative.CID exposing (CID, decoder, fromString, toString)

import Json.Decode exposing (Decoder)



-- 🌳


type CID
    = CID String



-- 🛠


fromString : String -> CID
fromString =
    CID


decoder : Decoder CID
decoder =
    Json.Decode.map CID Json.Decode.string


toString : CID -> String
toString (CID string) =
    string
