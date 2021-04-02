const DEFAULT_PORT_NAMES = {
  incoming: "webnativeRequest",
  outgoing: "webnativeResponse"
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

    let fs
    const builtInGetFs = () => fs


    /**
     * Handle request.
     */
    exports.request = function(request, elmApp, getFs = builtInGetFs, portNames = DEFAULT_PORT_NAMES) {
      switch (request.context) {
        case "WEBNATIVE": return webnativeRequest(elmApp, portNames, request)
        case "WNFS": return wnfsRequest(elmApp, getFs, portNames, request)
      }
    }


    /**
     * Setup the ports for our Elm app.
     */
    exports.setup = function (elmApp, getFs = builtInGetFs, portNames = DEFAULT_PORT_NAMES) {
      if (!elmApp.ports || !elmApp.ports[portNames.incoming]) {
        console.warn(`Couldn't find the incoming Elm port for webnative named "${portNames.incoming}". Could be that you haven't used the port yet, dead code elimination.`)
        return
      }

      if (!elmApp.ports[portNames.outgoing]) {
        console.warn(`Not sending webnative responses back to your Elm app, because the outgoing port named "${portNames.outgoing}" was not found. Could be that you haven't used the port yet, dead code elimination.`)
      }

      elmApp.ports[portNames.incoming].subscribe(request => {
        exports.request(request, elmApp, getFs, portNames)
      })
    }


    /**
     * Handle webnative request.
     */
    function webnativeRequest(elmApp, portNames, request) {
      Promise.resolve(webnative[request.method](
        ...request.arguments

      )).then(result => {
        switch (request.method) {
          // Don't send result to Elm
          case "redirectToLobby": return;
          case "loadFileSystem": fs = result; break;

          // Do something, but also report back to Elm
          case "initialise": fs = result.fs;

          // Report back to Elm
          default:
            if (elmApp.ports[portNames.outgoing]) elmApp.ports[portNames.outgoing].send({
              tag: request.tag,
              error: null,
              method: request.method,
              data: result,
              context: request.context
            })
        }

      }).catch(err => {
        if (elmApp.ports[portNames.outgoing]) elmApp.ports[portNames.outgoing].send({
          tag: request.tag,
          error: err.message || err,
          method: request.method,
          data: null,
          context: request.context
        })

      })
    }


    /**
     * Handle WNFS request.
     */
    function wnfsRequest(elmApp, getFs, portNames, request) {
      const method = request.method.replace(/_utf8$/, "")

      if (request.method === "write") {
        request.arguments = [
          request.arguments[0],
          Uint8Array.from(request.arguments[1])
        ]
      }

      Promise.resolve(getFs()).then(fs => fs[method](
        ...request.arguments

      )).then(data => {
        if (elmApp.ports[portNames.outgoing]) elmApp.ports[portNames.outgoing].send({
          tag: request.tag,
          error: null,
          method: request.method,
          data: data.root ? null : (data.buffer ? Array.from(data) : data),
          context: request.context
        })

      }).catch(err => {
        if (elmApp.ports[portNames.outgoing]) elmApp.ports[portNames.outgoing].send({
          tag: request.tag,
          error: err.message || err,
          method: request.method,
          data: null,
          context: request.context
        })

      })
    }

}))
