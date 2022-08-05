<img src="https://raw.githubusercontent.com/fission-code/kit/ec26048c4cfd3b6ec82e104d87d2c9a8315285ad/images/badge-solid-colored.svg" width="88" />

(There is also `fission-suite/webnative-elm`, but that package is outdated. Use this!)

# Webnative Elm

[![Built by FISSION](https://img.shields.io/badge/⌘-Built_by_FISSION-purple.svg)](https://fission.codes)
[![Discord](https://img.shields.io/discord/478735028319158273.svg)](https://discord.gg/zAQBDEq)
[![Discourse](https://img.shields.io/discourse/https/talk.fission.codes/topics)](https://talk.fission.codes)

A thin wrapper around [webnative](https://github.com/fission-codes/webnative#readme) for Elm.

> Fission helps developers build and scale their apps. We’re building a web native file system that combines files, encryption, and identity, like an open source iCloud.



# QuickStart

```shell
elm install fission-codes/webnative-elm

# requires webnative version 0.24 or later
npm install webnative
npm install webnative-elm
```

Setup the necessary ports on your Elm app.

```elm
port module Ports exposing (..)

import Webnative

port webnativeRequest : Webnative.Request -> Cmd msg
port webnativeResponse : (Webnative.Response -> msg) -> Sub msg

```

Then import the javascript portion of this library to connect up the ports.

```js
import * as webnativeElm from "webnative-elm"

// elmApp = Elm.Main.init()
webnativeElm.setup({ app: elmApp })
```

Once we have that setup, we can write our webnative Elm code.

```elm
import Webnative exposing (Artifact(..), DecodedResponse(..))
import Webnative.Path as Path
import Wnfs


-- INIT


appPermissions : Webnative.AppPermissions
appPermissions =
  { creator = "Fission", name = "Example" }


permissions : Webnative.Permissions
permissions =
  { app = Just appPermissions, fs = Nothing }


init : (Model, Cmd Msg)
init =
  ( {}
  , permissions
      |> Webnative.init
      |> Ports.webnativeRequest
      -- 🚀 We'll get a response in the `GotWebnativeResponse` msg
  )



-- FILESYSTEM PREP


type Tag
  = ReadHelloTxt
  | Mutation
  | PointerUpdated


base : Wnfs.Base
base =
  Wnfs.AppData appPermissions



-- UPDATE


type Msg
  = GotWebnativeResponse Webnative.Response
  --
  | ReadWnfsFile
  | WriteToWnfsFile


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GotWebnativeResponse response ->
      case Webnative.decodeResponse tagFromString response of
        -----------------------------------------
        -- 🚀
        -----------------------------------------
        Webnative ( Initialisation state ) ->
          if Webnative.isAuthenticated state then
            loadUserData
          else
            welcome

        -----------------------------------------
        -- 💾
        -----------------------------------------
        Wnfs ReadHelloTxt ( Utf8Content helloContents ) ->
          -- Do something with content from hello.txt

        Wnfs Mutation _ ->
          ( model
          , { tag = PointerUpdated }
              |> Wnfs.publish
              |> Ports.webnativeRequest
          )

        -----------------------------------------
        -- 🥵
        -----------------------------------------
        -- Do something with the errors,
        -- here we cast them to strings
        WebnativeError err -> Webnative.error err
        WnfsError err -> Wnfs.error err

    --

    ReadWnfsFile ->
      { path = Path.file [ "hello.txt" ]
      , tag = tagToString ReadHelloTxt
      }
        |> Wnfs.readUtf8 base
        |> Ports.webnativeRequest
        |> Tuple.pair model

    WriteToWnfsFile ->
      "👋"
        |> Wnfs.writeUtf8 base
          { path = Path.file [ "hello.txt" ]
          , tag = tagToString Mutation
          }
        |> Ports.webnativeRequest
        |> Tuple.pair model


subscriptions : Sub Msg
subscriptions =
  Ports.webnativeResponse GotWebnativeResponse



-- TAG ENCODING/DECODING


tagToString : Tag -> String
tagToString tag =
  case tag of
    ReadHelloTxt -> "ReadHelloTxt"
    Mutation -> "Mutation"


tagFromString : String -> Result String Tag
tagFromString string =
  case string of
    "ReadHelloTxt" -> Ok ReadHelloTxt
    "Mutation" -> Ok Mutation
    _ -> Err "Invalid tag"
```



# What's this tag thing?

You can chain webnative commands in Elm by providing a tag, which is then attached to the response. In the following example I have a custom type for my tags, which I then encode/decode to/from a string.

```elm
import Webnative exposing (DecodedResponse(..))
import Webnative.Path as Path
import Wnfs

type Tag = Mutation | PointerUpdated

-- Request
Wnfs.writeUtf8 base
  { path = Path.file [ "hello.txt" ]
  , tag = tagToString Mutation
  }

-- Response
case Webnative.decodeResponse tagFromString response of
  Wnfs Mutation _ ->
    ( model
    , Ports.webnativeRequest (Wnfs.publish PointerUpdated)
    )
```



# API

We don't support all the functions from [webnative](https://github.com/fission-codes/webnative#readme) yet.  
For now you can do the following from Elm:

- All WNFS interactions
- Redirect to lobby
- Leave / Sign out

More coming later.  
[Let us know](https://talk.fission.codes) if you have any requests.



# Filesystem

Alternatively you can load the filesystem separately.  
You may want to do this when working with a web worker.

```elm
import Webnative exposing (defaultInitOptions)

Webnative.initWithOptions
  { defaultInitOptions | loadFileSystem = False }
```

And then load it either in Elm or in javascript.

```elm
Webnative.loadFileSystem permissions
```

```js
const fs = await webnative.loadFileSystem(permissions)
webnativeElm.setup({ app: elmApp, getFs: () => fs })
```



# Customisation

There's various customisation options:

```js
webnativeElm.setup({
  app: elmApp,
  portNames: {
    incoming: "webnativeRequest",
    outgoing: "webnativeResponse"
  },
  webnative: require("webnative")
})
```
