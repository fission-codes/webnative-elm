module Webnative.Path.Encapsulated exposing (toDirectory, toFile)

{-|


# Encapsulated Paths

@docs toDirectory, toFile

-}

import Webnative.Path as Path exposing (Directory, Encapsulated, File, Kind(..), Path, directory, file)



-- EXTRACTION


{-| Remove the membrane and extract a `Path Directory`.
-}
toDirectory : Path Encapsulated -> Maybe (Path Directory)
toDirectory path =
    case Path.kind path of
        Directory ->
            path
                |> Path.unwrap
                |> directory
                |> Just

        File ->
            Nothing


{-| Remove the membrane and extract a `Path File`.
-}
toFile : Path Encapsulated -> Maybe (Path File)
toFile path =
    case Path.kind path of
        Directory ->
            Nothing

        File ->
            path
                |> Path.unwrap
                |> file
                |> Just
