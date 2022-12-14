import * as webnative from "webnative"
import * as webnativeElm from "webnative-elm"


const elmApp = Elm.Main.init({
  node: document.body.querySelector("#replaceme")
})


webnativeElm.setup({ app: elmApp })
