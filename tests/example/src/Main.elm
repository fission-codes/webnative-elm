module Main exposing (main)

import Browser
import Html
import Html.Events
import Ports
import Webnative exposing (Artifact(..), DecodedResponse(..), State(..))
import Wnfs exposing (Artifact(..))


main : Program () Model Msg
main =
    Browser.element
        { init =
            \_ ->
                permissions
                    |> Webnative.init
                    |> Ports.webnativeRequest
                    |> Tuple.pair { authenticated = False, loading = True }
        , update = update
        , subscriptions = subscriptions
        , view =
            \model ->
                let
                    _ =
                        Debug.log "" model
                in
                if model.loading then
                    Html.text "Loading 👀"

                else if not model.authenticated then
                    Html.button
                        [ Html.Events.onClick RedirectToAuth ]
                        [ Html.text "Authenticate" ]

                else
                    Html.text "Logged in! 👋"
        }



-- 📰


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.webnativeResponse GotWebnativeResponse



-- 🌳


type alias Model =
    { authenticated : Bool
    , loading : Bool
    }


type Tag
    = Query


permissions : Webnative.Permissions
permissions =
    { app = Nothing
    , fs = Nothing
    }



-- 📣


type Msg
    = RedirectToAuth
    | GotWebnativeResponse Webnative.Response


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RedirectToAuth ->
            ( model
            , Ports.webnativeRequest <|
                Webnative.redirectToLobby
                    Webnative.CurrentUrl
                    permissions
            )

        GotWebnativeResponse response ->
            let
                result =
                    Webnative.decodeResponse
                        tagFromString
                        response

                _ =
                    Debug.log "" result

                m =
                    { model | loading = False }
            in
            case result of
                -----------------------------------------
                -- 🌏
                -----------------------------------------
                Webnative (Initialisation state) ->
                    ( { m | authenticated = Webnative.isAuthenticated state }, Cmd.none )

                Webnative (Webnative.NoArtifact _) ->
                    ( m, Cmd.none )

                -----------------------------------------
                -- 💾
                -----------------------------------------
                Wnfs Query (Utf8Content string) ->
                    ( m, Cmd.none )

                Wnfs Query _ ->
                    ( m, Cmd.none )

                -----------------------------------------
                -- 🥵
                -----------------------------------------
                WnfsError err ->
                    let
                        _ =
                            Debug.todo (Wnfs.error err)
                    in
                    ( m
                    , Cmd.none
                    )

                WebnativeError err ->
                    let
                        _ =
                            Debug.todo (Webnative.error err)
                    in
                    ( m
                    , Cmd.none
                    )



-- TAG ENCODING/DECODING


tagToString : Tag -> String
tagToString tag =
    case tag of
        Query ->
            "Query"


tagFromString : String -> Result String Tag
tagFromString string =
    case string of
        "Query" ->
            Ok Query

        _ ->
            Err "Invalid tag"
