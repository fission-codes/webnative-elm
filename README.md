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
port wnfsRequest : Webnative.Request -> Cmd msg
port wnfsResponse : (Webnative.Response -> msg) -> Sub msg

```

Then import the javascript portion of this library to connect up the ports.

```js
import * as webnative from "webnative"
import * as webnativeElm from "webnative-elm"

// elmApp = Elm.Main.init()

webnative
  .initialise({
    permissions: {
      app: { creator: "Fission", name: "Example" }
    }
  })
  .then(state => {
    webnativeElm.setup(elmApp, state.fs)
  })
```

Once we have that setup, we need can write our webnative Elm code.

```elm
import Webnative
import Wnfs


type Msg
  = ReadWnfsFile
  | WriteToWnfsFile
    --
  | GotWnfsResponse

type Tag
  = ReadHelloTxt
  | Mutation


base : Wnfs.Base Webnative.Response
base =
  Wnfs.AppData
    { creator = "Fission"
    , name = "Example"
    }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ReadWnfsFile ->
      { path = [ "hello.txt" ]
      , tag = tagToString ReadHelloTxt
      }
        |> Wnfs.readUtf8 base
        |> Ports.wnfsRequest
        |> Tuple.pair model

    WriteToWnfsFile ->
      "👋"
        |> Wnfs.writeUtf8 base
          { path = [ "hello.txt" ]
          , tag = tagToString Mutation
          }
        |> Ports.wnfsRequest
        |> Tuple.pair model

    --

    GotWnfsResponse response ->
      case Wnfs.decodeResponse tagFromString response of
        Ok ( ReadHelloTxt, Wnfs.Utf8Content helloContents ) ->
          -- Do something with content from hello.txt

        Ok ( Mutation, _ ) ->
          ( model
          , Ports.wnfsRequest Wnfs.publish
          )

        Err errString ->
          -- Decoding, or tag parse, error.


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
type Tag = Mutation

-- Request
Wnfs.writeUtf8 base
  { path = [ "hello.txt" ]
  , tag = tagToString Mutation
  }

-- Response
case Wnfs.decodeResponse tagFromString response of
  Ok ( Mutation, _ ) ->
    ( model
    , Ports.wnfsRequest Wnfs.publish
    )
```



# API

We don't support all the functions from [webnative](https://github.com/fission-suite/webnative#readme) yet.  
For now you can do the following from Elm:

- All WNFS interactions
- Redirect to lobby

More coming later.  
[Let us know](https://talk.fission.codes) if you have any requests.



# Customisation

You can customise the port names by passing in a third parameter.

```js
webnativeElm.setup(elmApp, state.fs, {
  webnative: {
    incoming: "webnativeRequest"
  },
  wnfs: {
    incoming: "wnfsRequest",
    outgoing: "wnfsResponse"
  }
})
```
