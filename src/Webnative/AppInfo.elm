module Webnative.AppInfo exposing (AppInfo, appId, encode)

{-|

@docs AppInfo, appId, encode

-}

import Json.Encode as Json



-- 🌳


{-| -}
type alias AppInfo =
    { creator : String, name : String }



-- 🛠


{-| -}
appId : AppInfo -> String
appId { creator, name } =
    creator ++ "/" ++ name


{-| -}
encode : AppInfo -> Json.Value
encode { creator, name } =
    Json.object
        [ ( "creator", Json.string creator )
        , ( "name", Json.string name )
        ]
