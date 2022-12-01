module Webnative.FileSystem exposing (AssociatedIdentity, Base(..), Entry, FileSystem, acceptShare, account, add, cat, deactivate, decoder, directoryEntriesDecoder, encode, exists, historyStep, ls, mkdir, mv, publish, read, ref, rm, sharePrivate, symlink, withRef, withRefSplat, write)

import Bytes exposing (Bytes)
import Dict
import Json.Decode exposing (Decoder)
import Json.Encode as Json
import TaskPort
import Webnative.AppInfo exposing (AppInfo)
import Webnative.CID as CID exposing (CID)
import Webnative.Internal exposing (callTaskPort, encodeBytes, fileContentDecoder)
import Webnative.Path as Path exposing (Directory, File, Kind(..), Path)
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


type alias AssociatedIdentity =
    { rootDID : String
    , username : Maybe String
    }


{-| Directory `Entry`.
-}
type alias Entry =
    { cid : CID
    , name : String
    , kind : Kind
    , size : Int
    }



-- POSIX (FILES)


acceptShare : FileSystem -> { shareId : String, sharedBy : String } -> Task ()
acceptShare fs { shareId, sharedBy } =
    callTaskPort
        { function = "fileSystem.acceptShare"
        , valueDecoder = TaskPort.ignoreValue
        , argsEncoder = Json.object >> withRef fs
        }
        [ ( "shareId", Json.string shareId )
        , ( "sharedBy", Json.string sharedBy )
        ]


account : FileSystem -> Task AssociatedIdentity
account =
    callTaskPort
        { function = "fileSystem.account"
        , valueDecoder =
            Json.Decode.map2
                (\r u -> { rootDID = r, username = u })
                (Json.Decode.field "rootDID" Json.Decode.string)
                (Json.Decode.maybe <| Json.Decode.field "username" Json.Decode.string)
        , argsEncoder = ref
        }


add : FileSystem -> Base -> Path File -> Bytes -> Task ()
add fs base path content =
    callTaskPort
        { function = "fileSystem.add"
        , valueDecoder = TaskPort.ignoreValue
        , argsEncoder = Json.list identity >> withRefSplat fs
        }
        [ encodePath base path
        , encodeBytes content
        ]


cat : FileSystem -> Base -> Path File -> Task Bytes
cat fs base =
    callTaskPort
        { function = "fileSystem.cat"
        , valueDecoder = fileContentDecoder
        , argsEncoder = encodePath base >> withRef fs
        }


deactivate : FileSystem -> Task ()
deactivate =
    callTaskPort
        { function = "fileSystem.deactivate"
        , valueDecoder = TaskPort.ignoreValue
        , argsEncoder = ref
        }


exists : FileSystem -> Base -> Path File -> Task Bool
exists fs base =
    callTaskPort
        { function = "fileSystem.exists"
        , valueDecoder = Json.Decode.bool
        , argsEncoder = encodePath base >> withRef fs
        }


historyStep : FileSystem -> Task ()
historyStep =
    callTaskPort
        { function = "fileSystem.historyStep"
        , valueDecoder = TaskPort.ignoreValue
        , argsEncoder = ref
        }


ls : FileSystem -> Base -> Path Directory -> Task (List Entry)
ls fs base =
    callTaskPort
        { function = "fileSystem.ls"
        , valueDecoder = directoryEntriesDecoder
        , argsEncoder = encodePath base >> withRef fs
        }


mkdir : FileSystem -> Base -> Path Directory -> Task ()
mkdir fs base =
    callTaskPort
        { function = "fileSystem.mkdir"
        , valueDecoder = TaskPort.ignoreValue
        , argsEncoder = encodePath base >> withRef fs
        }


mv : FileSystem -> Base -> { from : Path k, to : Path k } -> Task ()
mv fs base { from, to } =
    callTaskPort
        { function = "fileSystem.mv"
        , valueDecoder = TaskPort.ignoreValue
        , argsEncoder = Json.list identity >> withRefSplat fs
        }
        [ encodePath base from
        , encodePath base to
        ]


publish : FileSystem -> Task CID
publish =
    callTaskPort
        { function = "fileSystem.publish"
        , valueDecoder = CID.decoder
        , argsEncoder = ref
        }


read : FileSystem -> Base -> Path File -> Task Bytes
read fs base =
    callTaskPort
        { function = "fileSystem.read"
        , valueDecoder = fileContentDecoder
        , argsEncoder = encodePath base >> withRef fs
        }


rm : FileSystem -> Base -> Path k -> Task ()
rm fs base =
    callTaskPort
        { function = "fileSystem.rm"
        , valueDecoder = TaskPort.ignoreValue
        , argsEncoder = encodePath base >> withRef fs
        }


sharePrivate : FileSystem -> List (Path k) -> { shareWith : List String } -> Task ()
sharePrivate fs paths { shareWith } =
    callTaskPort
        { function = "fileSystem.sharePrivate"
        , valueDecoder = TaskPort.ignoreValue
        , argsEncoder = Json.object >> withRef fs
        }
        [ ( "at", Json.list (encodePath Private) paths )
        , ( "shareWith", Json.list Json.string shareWith )
        ]


symlink : FileSystem -> Base -> { at : Path Directory, name : String, referringTo : Path k } -> Task ()
symlink fs base { at, name, referringTo } =
    callTaskPort
        { function = "fileSystem.symlink"
        , valueDecoder = TaskPort.ignoreValue
        , argsEncoder = Json.object >> withRef fs
        }
        [ ( "at", encodePath base at )
        , ( "name", Json.string name )
        , ( "referringTo", encodePath base referringTo )
        ]


write : FileSystem -> Base -> Path File -> Bytes -> Task ()
write fs base path content =
    callTaskPort
        { function = "fileSystem.write"
        , valueDecoder = TaskPort.ignoreValue
        , argsEncoder = Json.list identity >> withRefSplat fs
        }
        [ encodePath base path
        , encodeBytes content
        ]



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


directoryEntriesDecoder : Decoder (List Entry)
directoryEntriesDecoder =
    Json.Decode.map3
        (\cid isFile size ->
            { cid = cid
            , size = size
            , kind =
                if isFile then
                    File

                else
                    Directory
            }
        )
        (Json.Decode.oneOf
            [ Json.Decode.field "cid" CID.decoder
            , Json.Decode.field "pointer" CID.decoder
            ]
        )
        (Json.Decode.field "isFile" Json.Decode.bool)
        (Json.Decode.field "size" Json.Decode.int)
        |> Json.Decode.dict
        |> Json.Decode.map
            (\dict ->
                dict
                    |> Dict.toList
                    |> List.map
                        (\( name, { cid, kind, size } ) ->
                            { cid = cid
                            , kind = kind
                            , name = name
                            , size = size
                            }
                        )
            )


encode : FileSystem -> Json.Value
encode (FileSystemReference r) =
    Json.string r



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
