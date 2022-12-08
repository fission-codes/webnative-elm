import * as TaskPort from "elm-taskport/js/taskport.js"
import * as Webnative from "webnative"
import { Namespace } from "elm-taskport/js/namespace.js"
import { Maybe } from "webnative"


export type Reference = string


/**
 * Create TaskPort namespace.
 */
export function createTaskPortNamespace(): typeof Namespace {
  return TaskPort.createNamespace("fission-codes/webnative", "8.0.0")
}


/**
 * Setup the ports for our Elm app.
 *
 * @param program Existing programs to
 */
export function init(options: {
  fileSystems?: Webnative.FileSystem[]
  programs?: Webnative.Program[]
}): { taskPortNamespace: typeof Namespace } {
  const fileSystems: Record<string, Webnative.FileSystem> = Object.fromEntries(
    (options.fileSystems || []).map(fs => [ fileSystemRef(fs), fs ])
  )

  const programs: Record<string, Webnative.Program> = Object.fromEntries(
    (options.programs || []).map(program => [ programRef(program), program ])
  )

  const ns = createTaskPortNamespace()

  const withProg = fn => withProgram(programs, fn)
  const withFs = fn => withFileSystem(fileSystems, fn)

  ns.register("program", args => createProgram(programs, fileSystems, args))
  ns.register("loadFileSystem", withProg(p => args => loadFileSystem(fileSystems, p, args)))

  ns.register("auth_isUsernameAvailable", withProg(p => p.auth.isUsernameAvailable))
  ns.register("auth_isUsernameValid", withProg(p => p.auth.isUsernameValid))
  ns.register("auth_register", withProg(p => p.auth.register))
  ns.register("auth_session", withProg(p => p.auth.session))

  ns.register("capabilities_collect", withProg(p => p.capabilities.collect))
  ns.register("capabilities_request", withProg(p => p.capabilities.request))
  ns.register("capabilities_session", withProg(p => p.capabilities.session))

  ns.register("fileSystem_acceptShare", withFs(f => f.acceptShare))
  ns.register("fileSystem_account", withFs(f => f.account))
  ns.register("fileSystem_add", withFs(f => f.add))
  ns.register("fileSystem_cat", withFs(f => f.cat))
  ns.register("fileSystem_deactivate", withFs(f => f.deactivate))
  ns.register("fileSystem_exists", withFs(f => f.exists))
  ns.register("fileSystem_get", withFs(f => f.get))
  ns.register("fileSystem_historyStep", withFs(f => f.historyStep))
  ns.register("fileSystem_loadShare", withFs(f => f.loadShare))
  ns.register("fileSystem_ls", withFs(f => f.ls))
  ns.register("fileSystem_mkdir", withFs(f => f.mkdir))
  ns.register("fileSystem_mv", withFs(f => f.mv))
  ns.register("fileSystem_publish", withFs(f => f.publish))
  ns.register("fileSystem_read", withFs(f => f.read))
  ns.register("fileSystem_resolveSymlink", withFs(f => f.resolveSymlink))
  ns.register("fileSystem_rm", withFs(f => f.rm))
  ns.register("fileSystem_sharePrivate", withFs(f => f.sharePrivate))
  ns.register("fileSystem_symlink", withFs(f => f.symlink))
  ns.register("fileSystem_write", withFs(f => f.write))

  return { taskPortNamespace: ns }
}



// TASKS


function createProgram(
  programs: Record<string, Webnative.Program>,
  fileSystems: Record<string, Webnative.FileSystem>,
  config: Webnative.Configuration
): Promise<
  { ok: { fs: string | null, program: string, session: Webnative.Session | null } } | { err: string }
> {
  return Webnative.program(config).then(
    program => {
      const programRef = Webnative.namespace(config)
      programs[ programRef ] = program

      const fsRef = program.session?.fs ? fileSystemRef(program.session.fs) : null
      if (fsRef && program.session?.fs) fileSystems[ fsRef ] = program.session.fs

      return { ok: encodeProgram(program) }
    },
    error => {
      return { err: typeof error === "string" ? error : error.message || "Unknown error" }
    }
  )
}


async function loadFileSystem(
  fileSystems: Record<string, Webnative.FileSystem>,
  program: Webnative.Program,
  username: string
) {
  const fs = await program.loadFileSystem(username)
  const fsRef = fileSystemRef(fs)
  fileSystems[ fsRef ] = fs
  return fsRef
}



// 🛠


export function encodeProgram(program: Webnative.Program): {
  fs: Maybe<Reference>,
  program: Reference,
  session: Maybe<Webnative.Session>
} {
  const fs = program.session && program.session.fs ? fileSystemRef(program.session.fs) : null
  return { fs, program: programRef(program), session: program.session }
}


export function fileSystemRef(fs: Webnative.FileSystem): string {
  return fs.account.rootDID
}


export function programRef(program: Webnative.Program): Reference {
  return Webnative.namespace(program.configuration)
}


function withFileSystem(
  fileSystems: Record<string, Webnative.FileSystem>,
  fn: (program: Webnative.FileSystem) => unknown
) {
  return ({ arg, fsRef, useSplat }) => {
    const fs = fileSystems[ fsRef ]
    const innerValue = fn(fs)
    if (typeof innerValue !== "function") return innerValue
    return useSplat ? innerValue(...arg) : innerValue(arg)
  }
}


function withProgram(
  programs: Record<string, Webnative.Program>,
  fn: (program: Webnative.Program) => unknown
) {
  return ({ arg, programRef, useSplat }) => {
    const program = programs[ programRef ]
    const innerValue = fn(program)
    if (typeof innerValue !== "function") return innerValue
    return useSplat ? innerValue(...arg) : innerValue(arg)
  }
}