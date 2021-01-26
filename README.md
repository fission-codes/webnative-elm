![](https://raw.githubusercontent.com/fission-suite/kit/6a20e9af963dd000903b1c6e64f9fbb2102ba472/images/badge-solid-colored.svg)

# Webnative Elm

[![Built by FISSION](https://img.shields.io/badge/⌘-Built_by_FISSION-purple.svg)](https://fission.codes)
[![Discord](https://img.shields.io/discord/478735028319158273.svg)](https://discord.gg/zAQBDEq)
[![Discourse](https://img.shields.io/discourse/https/talk.fission.codes/topics)](https://talk.fission.codes)

A thin wrapper around [webnative](https://github.com/fission-suite/webnative#readme) for Elm.

> Fission helps developers build and scale their apps. We’re building a web native file system that combines files, encryption, and identity, like an open source iCloud.



# QuickStart

```
elm install fission-suite/webnative-elm
npm install webnative-elm webnative
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
import * as webnative from "webnative"
import * as webnativeElm from "webnative-elm"

// elmApp = Elm.Main.init()

webnativeElm.setup(elmApp)
```

Once we have that setup, we can write our webnative Elm code.

```elm
import Webnative exposing (Context(..))
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
        Ok ( _, _, Initialisation state ) ->
          if Webnative.isAuthenticated state then
            loadUserData
          else
            welcome

        -----------------------------------------
        -- 💾
        -----------------------------------------
        Ok ( Wnfs, Just ReadHelloTxt, Wnfs.Utf8Content helloContents ) ->
          -- Do something with content from hello.txt

        Ok ( Wnfs, Just Mutation, _ ) ->
          ( model
          , Ports.webnativeRequest Wnfs.publish
          )

        -----------------------------------------
        -- 🥵
        -----------------------------------------
        Err ( maybeContext, errString ) ->
          -- Initialisation error, tag parse error, etc.

    --

    ReadWnfsFile ->
      { path = [ "hello.txt" ]
      , tag = tagToString ReadHelloTxt
      }
        |> Wnfs.readUtf8 base
        |> Ports.webnativeRequest
        |> Tuple.pair model

    WriteToWnfsFile ->
      "👋"
        |> Wnfs.writeUtf8 base
          { path = [ "hello.txt" ]
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
import Webnative exposing (Context(..))
import Wnfs

type Tag = Mutation

-- Request
Wnfs.writeUtf8 base
  { path = [ "hello.txt" ]
  , tag = tagToString Mutation
  }

-- Response
case Webnative.decodeResponse tagFromString response of
  Ok ( Wnfs, Just Mutation, _ ) ->
    ( model
    , Ports.webnativeRequest Wnfs.publish
    )
```

Request from the `Webnative` module don't have tags, that's why we're using a `Maybe`.



# API

We don't support all the functions from [webnative](https://github.com/fission-suite/webnative#readme) yet.  
For now you can do the following from Elm:

- All WNFS interactions
- Redirect to lobby

More coming later.  
[Let us know](https://talk.fission.codes) if you have any requests.



# Filesystem

Alternatively you can load the filesystem separately.  
You may want to do this when working with a web worker.

```elm
import Webnative exposing (defaultInitOptions)

Webnative.initWithOptions
  { defaultInitOptions | loadFilesystem = False }
```

And then load it either in Elm or in javascript.

```elm
Webnative.loadFilesystem permissions
```

```js
const fs = await webnative.loadFilesystem(permissions)
webnativeElm.setup(elmApp, () => fs)
```



# Customisation

You can customise the port names by passing in a third parameter.

```js
webnativeElm.setup(elmApp, undefined, {
  incoming: "webnativeRequest",
  outgoing: "webnativeResponse"
})
```
