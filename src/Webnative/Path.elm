module Webnative.Path exposing
    ( Path, Directory, File, Encapsulated, Kind(..)
    , directory, file, root
    , fromPosix, toPosix
    , encapsulate
    , kind, unwrap
    , encode
    )

{-|


# Paths

@docs Path, Directory, File, Encapsulated, Kind


# Creation

@docs directory, file, root


# POSIX

@docs fromPosix, toPosix


# Encapsulation

@docs encapsulate


# Functions

@docs kind, unwrap


# Miscellaneous

@docs encode

-}

import Json.Encode as Json



-- 🌳


{-| Path type.

This is used with the [phantom 👻 types](#phantom-types).

    directoryPath : Path Directory

    filePath : Path File

    encapsulatedPath : Path Encapsulated

-}
type Path t
    = Path Kind (List String)


{-| -}
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

    directory [ "Audio", "Playlists" ]

-}
directory : List String -> Path Directory
directory =
    Path Directory


{-| Create a file path.

    file [ "Document", "invoice.pdf" ]

-}
file : List String -> Path File
file =
    Path File


{-| Root directory.
-}
root : Path Directory
root =
    directory []



-- POSIX


{-| Convert a POSIX formatted string to a path.

This will return a `Encapsulated` path. To get a path of the type `Path Directory` or `Path File`, use the functions in the `Webnative.Path.Encapsulated` module.

    >>> import Webnative.Path.Encapsulated

    >>> "foo/bar/"
    ..>   |> fromPosix
    ..>   |> Webnative.Path.Encapsulated.toDirectory
    Just (directory [ "foo", "bar" ])

    >>> "foo/bar"
    ..>   |> fromPosix
    ..>   |> Webnative.Path.Encapsulated.toFile
    Just (file [ "foo", "bar" ])

-}
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


{-| Convert a path to the POSIX format.

    >>> toPosix (directory [ "foo", "bar"])
    "foo/bar/"

    >>> toPosix (file [ "foo", "bar"])
    "foo/bar"

-}
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


{-| Get the path kind.

    >>> kind (directory [])
    Directory

    >>> kind (file [])
    File

-}
kind : Path t -> Kind
kind (Path k _) =
    k


{-| Get the path parts.

    >>> unwrap (directory [ "foo", "bar" ])
    [ "foo", "bar" ]

    >>> unwrap (file [ "foo", "bar" ])
    [ "foo", "bar" ]

-}
unwrap : Path t -> List String
unwrap (Path _ parts) =
    parts



-- MISCELLANEOUS


{-| Encode to JSON.

    >>> import Json.Encode

    >>> [ "foo" ]
    ..>   |> directory
    ..>   |> encode
    ..>   |> Json.Encode.encode 0
    "{\"directory\":[\"foo\"]}"

    >>> [ "bar" ]
    ..>   |> file
    ..>   |> encode
    ..>   |> Json.Encode.encode 0
    "{\"file\":[\"bar\"]}"

-}
encode : Path t -> Json.Value
encode (Path k p) =
    Json.object
        [ ( case k of
                Directory ->
                    "directory"

                File ->
                    "file"
          , Json.list Json.string p
          )
        ]
