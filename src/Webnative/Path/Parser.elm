module Webnative.Path.Parser exposing (..)

import Webnative.Path as Path exposing (Directory, File, Kind(..), Parsed, Path, directory, file)



-- TRANSFORMERS


toDirectory : Path Parsed -> Result String (Path Directory)
toDirectory path =
    case Path.kind path of
        Directory ->
            path
                |> Path.unwrap
                |> directory
                |> Ok

        File ->
            Err "Parsed path is a File path, expected Directory"


toFile : Path Parsed -> Result String (Path File)
toFile path =
    case Path.kind path of
        Directory ->
            Err "Parsed path is a Directory path, expected File"

        File ->
            path
                |> Path.unwrap
                |> file
                |> Ok
