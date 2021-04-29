module Webnative.Path exposing (Directory, File, Kind(..), Parsed, Path, directory, file, fromPosix, kind, toPosix, unwrap)

{-|


# Path

-}

-- 🌳


{-| Path type.
-}
type Path t
    = Path Kind (List String)


{-| Kind.
-}
type Kind
    = Directory
    | File



-- PHANTOM TYPES


{-| 👻 Directory
-}
type Directory
    = Directory_


{-| 👻 File
-}
type File
    = File_


{-| 👻 Parsed
-}
type Parsed
    = Parsed_



-- CREATION


directory : List String -> Path Directory
directory =
    Path Directory


file : List String -> Path File
file =
    Path File



-- POSIX


fromPosix : String -> Path Parsed
fromPosix string =
    string
        |> (\s ->
                if String.startsWith "/" s then
                    String.dropLeft 1 s

                else
                    s
           )
        |> (\s ->
                if String.endsWith "/" s then
                    Path Directory (String.split "/" <| String.dropRight 1 s)

                else
                    Path File (String.split "/" s)
           )


toPosix : Path t -> String
toPosix (Path k parts) =
    let
        joined =
            String.join "/" parts
    in
    case k of
        Directory ->
            joined ++ "/"

        File ->
            joined



-- 🛠


kind : Path t -> Kind
kind (Path k _) =
    k


unwrap : Path t -> List String
unwrap (Path _ parts) =
    parts
