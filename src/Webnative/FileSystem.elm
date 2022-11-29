module Webnative.FileSystem exposing (..)

import Json.Decode exposing (Decoder)



-- 🌳


type FileSystem
    = FileSystemReference String



-- 🛠


decoder : Decoder FileSystem
decoder =
    Json.Decode.map FileSystemReference Json.Decode.string
