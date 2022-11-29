; (function (root, factory) {
  if (typeof exports === "object" && typeof exports.nodeName !== "string") {
    // CommonJS
    factory(exports, require("elm-taskport"), require("webnative"))
  } else {
    // Browser globals
    factory((root.webnativeElm = {}), root.TaskPort, root.webnative)
  }

}(typeof self !== "undefined" ? self : this, function (exports, tp, wn) {

  const fileSystems = {}
  const programs = {}


  /**
   * Create TaskPort namespace.
   */
  exports.createTaskPortNamespace = function () {
    return tp.createNamespace("fission-codes/webnative", "8.0.0")
  }


  /**
   * Setup the ports for our Elm app.
   */
  exports.init = function ({
    taskPort,
    webnative
  }) {
    if (taskPort) tp = taskPort
    if (webnative) wn = webnative

    const ns = exports.createTaskPortNamespace()

    if (!tp) throw new Error("Failed to load elm-taskport")
    if (!wn) throw new Error("Failed to load webnative")

    ns.register("program", createProgram)

    ns.register("auth.isUsernameAvailable", withProgram(p => p.auth.isUsernameAvailable))
    ns.register("auth.isUsernameValid", withProgram(p => p.auth.isUsernameValid))
    ns.register("auth.register", withProgram(p => p.auth.register))
    ns.register("auth.session", withProgram(p => p.auth.session))

    ns.register("capabilities.collect", withProgram(p => p.capabilities.collect))
    ns.register("capabilities.request", withProgram(p => p.capabilities.request))
    ns.register("capabilities.session", withProgram(p => p.capabilities.session))

    return { taskPortNamespace: ns }
  }



  // TASKS
  // -----

  function createProgram(config) {
    return wn.program(config).then(
      program => {
        const programRef = wn.namespace(config)
        programs[ programRef ] = program

        const fsRef = program.session && program.session.fs ? fileSystemRef(program.session.fs) : null
        if (fsRef) fileSystems[ fsRef ] = program.session.fs

        return { ok: encodeProgram(program, programRef) }
      },
      error => {
        return { err: error }
      }
    )
  }



  // 🛠


  function encodeProgram(program, programRef) {
    return { ref: programRef, session: program.session }
  }


  function fileSystemRef(fs) {
    return fs.account.rootDID
  }


  function withProgram(fn) {
    return ({ arg, programRef, useSplat }) => {
      const program = programs[ programRef ]
      const innerFn = fn(program)
      return useSplat ? innerFn(...arg) : innerFn(arg)
    }
  }

}))
