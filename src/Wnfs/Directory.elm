module Wnfs.Directory exposing (Entry, Kind(..))

{-| Types for directory listings.

@docs Entry, Kind

-}

-- 🌳


{-| Kind of `Entry`.
-}
type Kind
    = Directory
    | File


{-| Directory `Entry`.
-}
type alias Entry =
    { cid : String
    , name : String
    , kind : Kind
    , size : Int
    }
