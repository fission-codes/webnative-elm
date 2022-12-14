import * as webnative from "webnative"
import * as webnativeElm from "webnative-elm"

console.log(webnativeElm)

document.body.innerHTML = typeof webnativeElm.setup === "function"
  ? "Success"
  : "Failed"
