module Webnative.FileSystem exposing (Base(..), FileSystem, decoder, encode, read, ref, withRef, withRefSplat)

import Bytes exposing (Bytes)
import Json.Decode exposing (Decoder)
import Json.Encode as Json
import Webnative.AppInfo exposing (AppInfo)
import Webnative.Internal exposing (callTaskPort, fileContentDecoder)
import Webnative.Path as Path exposing (File, Path)
import Webnative.Task exposing (Task)



-- 🌳


type FileSystem
    = FileSystemReference String


{-| Base of the WNFS action.
-}
type Base
    = AppData AppInfo
    | Private
    | Public



-- POSIX


read : FileSystem -> Base -> Path File -> Task Bytes
read fs base =
    callTaskPort
        { function = "fileSystem.read"
        , valueDecoder = fileContentDecoder
        , argsEncoder = encodePath base >> withRef fs
        }



-- REFERENCE


ref : FileSystem -> Json.Value
ref fileSystem =
    Json.object
        [ ( "fileSystemRef", encode fileSystem ) ]


withRef : FileSystem -> Json.Value -> Json.Value
withRef fileSystem arg =
    Json.object
        [ ( "fileSystemRef", encode fileSystem )
        , ( "arg", arg )
        ]


withRefSplat : FileSystem -> Json.Value -> Json.Value
withRefSplat fileSystem arg =
    Json.object
        [ ( "fileSystemRef", encode fileSystem )
        , ( "arg", arg )
        , ( "useSplat", Json.bool True )
        ]



-- 🛠


decoder : Decoder FileSystem
decoder =
    Json.Decode.map FileSystemReference Json.Decode.string


encode : FileSystem -> Json.Value
encode (FileSystemReference r) =
    Json.string r



-- directoryContentDecoder : Json.Decode.Decoder (List Wnfs.Entry)
-- directoryContentDecoder =
--     Json.Decode.map3
--         (\cid isFile size ->
--             { cid = cid
--             , size = size
--             , kind =
--                 if isFile then
--                     File
--                 else
--                     Directory
--             }
--         )
--         (Json.Decode.oneOf
--             [ Json.Decode.field "cid" Json.Decode.string
--             , Json.Decode.field "pointer" Json.Decode.string
--             ]
--         )
--         (Json.Decode.field "isFile" Json.Decode.bool)
--         (Json.Decode.field "size" Json.Decode.int)
--         |> Json.Decode.dict
--         |> Json.Decode.map
--             (\dict ->
--                 dict
--                     |> Dict.toList
--                     |> List.map
--                         (\( name, { cid, kind, size } ) ->
--                             { cid = cid
--                             , kind = kind
--                             , name = name
--                             , size = size
--                             }
--                         )
--             )
--
-- ㊙️


encodePath : Base -> Path k -> Json.Value
encodePath base path =
    path
        |> Path.map
            (\parts ->
                case base of
                    AppData { creator, name } ->
                        [ "private", "Apps", creator, name ] ++ parts

                    Private ->
                        "private" :: parts

                    Public ->
                        "public" :: parts
            )
        |> Path.encode
