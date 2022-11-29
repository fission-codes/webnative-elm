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

    return { taskPortNamespace: ns }
  }



  // TASKS
  // -----

  function createProgram(config) {
    return wn.program(config).then(
      program => {
        const programId = wn.namespace(config)
        programs[ programId ] = program

        const fsId = program.session && program.session.fs ? fileSystemId(program.session.fs) : null
        if (fsId) fileSystems[ fsId ] = program.session.fs

        return { ok: encodeProgram(program) }
      },
      error => {
        return { err: error }
      }
    )
  }



  // 🛠


  function encodeProgram(program) {
    return { session: encodeSession(program.session) }
  }


  function encodeSession({ username, type }) {
    return { kind: type, username }
  }


  function fileSystemId(fs) {
    return fs.account.rootDID
  }

}))
