module Webnative.Path.Encapsulated exposing (..)

{-|


# Encapsulated Paths

-}

import Webnative.Path as Path exposing (Directory, Encapsulated, File, Kind(..), Path, directory, file)



-- EXTRACTION


{-| Remove the membrane and extract a `Path Directory`.
-}
toDirectory : Path Encapsulated -> Result String (Path Directory)
toDirectory path =
    case Path.kind path of
        Directory ->
            path
                |> Path.unwrap
                |> directory
                |> Ok

        File ->
            Err "Encapsulated path is a File path, expected Directory"


{-| Remove the membrane and extract a `Path File`.
-}
toFile : Path Encapsulated -> Result String (Path File)
toFile path =
    case Path.kind path of
        Directory ->
            Err "Encapsulated path is a Directory path, expected File"

        File ->
            path
                |> Path.unwrap
                |> file
                |> Ok
