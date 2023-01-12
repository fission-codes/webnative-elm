module Webnative.Namespace exposing (Namespace, fromAppInfo, fromString, toString)

{-|

@docs Namespace, fromAppInfo, fromString, toString

-}

import Webnative.AppInfo as AppInfo exposing (AppInfo)



-- 🌳


{-| -}
type Namespace
    = NsAppInfo AppInfo
    | NsString String



-- 🛠


{-| -}
fromAppInfo : AppInfo -> Namespace
fromAppInfo =
    NsAppInfo


{-| -}
fromString : String -> Namespace
fromString =
    NsString


{-| -}
toString : Namespace -> String
toString namespace =
    case namespace of
        NsAppInfo appInfo ->
            AppInfo.appId appInfo

        NsString string ->
            string
