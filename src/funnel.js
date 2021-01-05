const DEFAULT_PORT_NAMES = {
  webnative: {
    incoming: "webnativeRequest",
    // outgoing: "webnativeResponse"
  },
  wnfs: {
    incoming: "wnfsRequest",
    outgoing: "wnfsResponse"
  }
}


;(function (root, factory) {
  if (typeof exports === "object" && typeof exports.nodeName !== "string") {
    // CommonJS
    factory(exports, require("webnative"))
  } else {
    // Browser globals
    factory((root.webnativeElm = {}), root.webnative)
  }

}(typeof self !== "undefined" ? self : this, function (exports, webnative) {

    /**
     * Setup the ports for our Elm app.
     */
    exports.setup = function (elmApp, fs, portNames = DEFAULT_PORT_NAMES) {
      elmApp.ports[portNames.webnative.incoming].subscribe(request => {
        webnative[request.method](
          ...request.arguments
        )
      })

      elmApp.ports[portNames.wnfs.incoming].subscribe(request => {
        const method = request.method.replace(/_utf8$/, "")

        if (request.method === "write") {
          request.arguments = [
            request.arguments[0],
            Uint8Array.from(request.arguments[1])
          ]
        }

        fs[method](
          ...request.arguments

        ).then(data => {
          elmApp.ports[portNames.wnfs.outgoing].send({
            tag: request.tag,
            method: request.method,
            data: data.root ? null : (data.buffer ? Array.from(data) : data)
          })

        })
      })
    }

}))
