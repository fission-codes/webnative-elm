module Webnative.Task exposing (..)

import Task
import Webnative.Error as Webnative



-- 🌳


type alias Task a =
    Task.Task Webnative.Error a



-- 🛠


attempt : { error : Webnative.Error -> msg, ok : value -> msg } -> Task value -> Cmd msg
attempt { error, ok } =
    Task.attempt
        (\result ->
            case result of
                Err e ->
                    error e

                Ok o ->
                    ok o
        )
