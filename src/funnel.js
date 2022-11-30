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
    ns.register("loadFileSystem", loadFileSystem)
    ns.register("loadRootFileSystem", loadRootFileSystem)

    ns.register("auth.isUsernameAvailable", withProgram(p => p.auth.isUsernameAvailable))
    ns.register("auth.isUsernameValid", withProgram(p => p.auth.isUsernameValid))
    ns.register("auth.register", withProgram(p => p.auth.register))
    ns.register("auth.session", withProgram(p => p.auth.session))

    ns.register("capabilities.collect", withProgram(p => p.capabilities.collect))
    ns.register("capabilities.request", withProgram(p => p.capabilities.request))
    ns.register("capabilities.session", withProgram(p => p.capabilities.session))

    ns.register("fileSystem.acceptShare", withFileSystem(f => f.acceptShare))
    ns.register("fileSystem.account", withFileSystem(f => f.account))
    ns.register("fileSystem.add", withFileSystem(f => f.add))
    ns.register("fileSystem.cat", withFileSystem(f => f.cat))
    ns.register("fileSystem.deactivate", withFileSystem(f => f.deactivate))
    ns.register("fileSystem.exists", withFileSystem(f => f.exists))
    ns.register("fileSystem.get", withFileSystem(f => f.get))
    ns.register("fileSystem.historyStep", withFileSystem(f => f.historyStep))
    ns.register("fileSystem.loadShare", withFileSystem(f => f.loadShare))
    ns.register("fileSystem.ls", withFileSystem(f => f.ls))
    ns.register("fileSystem.mkdir", withFileSystem(f => f.mkdir))
    ns.register("fileSystem.mv", withFileSystem(f => f.mv))
    ns.register("fileSystem.publish", withFileSystem(f => f.publish))
    ns.register("fileSystem.read", withFileSystem(f => f.read))
    ns.register("fileSystem.resolveSymlink", withFileSystem(f => f.resolveSymlink))
    ns.register("fileSystem.rm", withFileSystem(f => f.rm))
    ns.register("fileSystem.sharePrivate", withFileSystem(f => f.sharePrivate))
    ns.register("fileSystem.symlink", withFileSystem(f => f.symlink))
    ns.register("fileSystem.write", withFileSystem(f => f.write))

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


  async function loadFileSystem(username) {
    const fs = await program.loadFileSystem(username)
    const fsRef = fileSystemRef(fs)
    fileSystems[ fsRef ] = fs
    return fsRef
  }


  async function loadRootFileSystem(username) {
    const fs = await program.loadRootFileSystem(username)
    const fsRef = fileSystemRef(fs)
    fileSystems[ fsRef ] = fs
    return fsRef
  }



  // 🛠


  function encodeProgram(program, programRef) {
    return { ref: programRef, session: program.session }
  }


  function fileSystemRef(fs) {
    return fs.account.rootDID
  }


  function withFileSystem(fn) {
    return ({ arg, fsRef, useSplat }) => {
      const fs = fileSystems[ fsRef ]
      const innerValue = fn(fs)
      if (typeof innerValue !== "function") return innerValue
      return useSplat ? innerValue(...arg) : innerValue(arg)
    }
  }


  function withProgram(fn) {
    return ({ arg, programRef, useSplat }) => {
      const program = programs[ programRef ]
      const innerValue = fn(program)
      if (typeof innerValue !== "function") return innerValue
      return useSplat ? innerValue(...arg) : innerValue(arg)
    }
  }

}))
