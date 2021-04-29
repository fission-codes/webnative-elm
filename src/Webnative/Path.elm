module Webnative.Path exposing
    ( Path, Directory, File, Encapsulated, Kind(..)
    , directory, file
    , fromPosix, toPosix
    , kind, unwrap
    )

{-|


# Paths

@docs Path, Directory, File, Encapsulated, Kind


# Creation

@docs directory, file


# POSIX

@docs fromPosix, toPosix


# Encapsulation

@docs encapsulate, forPermissions

-}

-- 🌳


{-| Path type.

This is used with the [phantom types](#phantom-types).

    ```elm
    directoryPath : Path Directory
    filePath : Path File
    encapsulatedPath : Path Encapsulated
    ```

-}
type Path t
    = Path Kind (List String)


{-| Kind.

Used to co

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


{-| 👻 Encapsulated
-}
type Encapsulated
    = Encapsulated_



-- CREATION


{-| Create a directory path.

    ```elm
    directory [ "Audio", "Playlists" ]
    ```

-}
directory : List String -> Path Directory
directory =
    Path Directory


{-| Create a file path.

    ```elm
    file [ "Document", "invoice.pdf" ]
    ```

-}
file : List String -> Path File
file =
    Path File



-- POSIX


fromPosix : String -> Path Encapsulated
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



-- ENCAPSULATE


{-| Encapsulate a path.
-}
encapsulate : Path t -> Path Encapsulated
encapsulate (Path k p) =
    Path k p



-- 🛠


kind : Path t -> Kind
kind (Path k _) =
    k


unwrap : Path t -> List String
unwrap (Path _ parts) =
    parts
