<img src="https://webnative.dev/webnative-full.svg" width="230" />

[![Built by FISSION](https://img.shields.io/badge/⌘-Built_by_FISSION-purple.svg)](https://fission.codes)
[![Discord](https://img.shields.io/discord/478735028319158273.svg)](https://discord.gg/zAQBDEq)
[![Discourse](https://img.shields.io/discourse/https/talk.fission.codes/topics)](https://talk.fission.codes)

**A thin wrapper around [Webnative](https://github.com/fission-codes/webnative#readme) for Elm.**

The Webnative SDK empowers developers to build fully distributed web applications without needing a complex back-end. The SDK provides:

- **User accounts** via the browser's [Web Crypto API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Crypto_API) or by using a blockchain wallet as a [webnative plugin](https://github.com/fission-codes/webnative-walletauth).
- **Authorization** using [UCAN](https://ucan.xyz/).
- **Encrypted file storage** via the [Webnative File System](https://guide.fission.codes/developers/webnative/file-system-wnfs) backed by [IPLD](https://ipld.io/).
- **Key management** via websockets and a two-factor auth-like flow.

Webnative applications work offline and store data encrypted for the user by leveraging the power of the web platform. You can read more about Webnative in Fission's [Webnative Guide](https://guide.fission.codes/developers/webnative). There's also an API reference which can be found at [webnative.fission.app](https://webnative.fission.app)



# QuickStart

```shell
elm install fission-codes/webnative-elm

# requires webnative version 0.36 or later
npm install webnative
npm install webnative-elm
```

Then import the javascript portion of this library and elm-taskport.
We'll need to initialise both of these.

```js
import * as TaskPort from "elm-taskport"
import * as WebnativeElm from "webnative-elm"

TaskPort.install()
WebnativeElm.init({ TaskPort })

// elmApp = Elm.Main.init()
```

Once we have that setup, we can write our Webnative Elm code. The following is an entire Webnative app which creates or links a user account, manages user sessions and their file system, and writes to and reads from that file system.

```elm
import Task
import Webnative
import Webnative.Auth
import Webnative.Configuration
import Webnative.Error exposing (Error)
import Webnative.FileSystem exposing (Base(..), FileSystem)
import Webnative.Namespace
import Webnative.Path as Path
import Webnative.Program exposing (Program)
import Webnative.Session exposing (Session)


-- INIT


appInfo : Webnative.AppInfo
appInfo =
  { creator = "Webnative", name = "Example" }


config : Webnative.Configuration
config =
  appInfo
    |> Webnative.Namespace.fromAppInfo
    |> Webnative.Configuration.fromNamespace


type Model
  = Unprepared
  | NotAuthenticated Program
  | Authenticated Program Session FileSystem


init : (Model, Cmd Msg)
init =
  ( Unprepared
  , -- 🚀
    config
      |> Webnative.program
      |> Webnative.attemptTask
          { ok = Liftoff
          , err = HandleWebnativeError
          }
  )



-- UPDATE


type Msg
  = HandleWebnativeError Error
  | GotFileContents String
  | GotSession Session
  | Liftoff Foundation
  | RegisterUser { success : Bool }


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    -----------------------------------------
    -- 🚀
    -----------------------------------------
    Liftoff foundation ->
      let
        newModel =
          -- Previous authenticated session?
          -- Presence of a FileSystem depends on your configuration.
          case (foundation.fileSystem, foundation.session) of
            (Just fs, Just session) -> Authenticated program session fs
            _                       -> NotAuthenticated program
      in
      ( newModel

      -- Next action
      --------------
      , case newModel of
          NotAuthenticated program ->
            -- Option (A), register a new account.
            -- We're skipping the username validation and
            -- username availability checking here to keep it short.
            { email = Nothing
            , username = Just "user"
            }
            |> Webnative.Auth.register program
            |> Webnative.attemptTask
                { ok = RegisterUser
                , error = HandleWebnativeError
                }

            -- Option (B), link an existing account.
            -- See 'Linking' section below.
          
          _ ->
            Cmd.none
      )

    -----------------------------------------
    -- 🙋
    -----------------------------------------
    RegisterUser { success } ->
      if success then
        ( model
        , program
            |> Webnative.Auth.sessionWithFileSystem
            |> Webnative.attemptTask
                { ok = RegisterUser
                , error = HandleWebnativeError
                }
        )
      else
        -- Could show message in create-account form.
        (model, Cmd.none)

    GotSessionAndFileSystem (Just { fileSystem, session }) ->
      ( -- Authenticated
        case model of
          NotAuthenticated program  -> Authenticated program session fileSystem
          _                         -> model

      -- Next action
      --------------
      , let
          path =
            Path.file [ "Sub Directory", "hello.txt" ]
        in
        "👋"
            |> Webnative.FileSystem.writeUtf8 fileSystem Private path
            |> Task.andThen (\_ -> Webnative.FileSystem.publish fileSystem)
            |> Task.andThen (\_ -> Webnative.FileSystem.readUtf8 fileSystem Private path)
            |> Webnative.attemptTask
                { ok = GotFileContents
                , error = HandleWebnativeError
                }
      )

    -----------------------------------------
    -- 💾
    -----------------------------------------
    GotFileContents string -> ...

    -----------------------------------------
    -- 🥵
    -----------------------------------------
    HandleWebnativeError UnsupportedBrowser ->        -- No indexedDB? Depends on how Webnative is configured.
    HandleWebnativeError InsecureContext ->           -- Webnative requires a secure context
    HandleWebnativeError (JavascriptError string) ->  -- Notification.push ("Got JS error: " ++ string)
```



# Linking

When a user has already registered an account, they can link a device instead.

```elm
-- TODO: Yet to be implemented
```



# Filesystem

Alternatively you can load the filesystem separately.  
You may want to do this when working with a web worker.

```elm
import Webnative

config =
  { namespace = ...
  
  --
  , debug = Nothing
  , fileSystem = Just { loadImmediately = Just True, version = Nothing }
  , permissions = Nothing
  }

Webnative.program config
```

And then load it either in Elm or in javascript.

```elm
Webnative.FileSystem.load program { username = "username" }
```

```js
const fs = await program.loadFileSystem("username")
webnativeElm.init({ fileSystems: [ fs ] })
```
