import * as Webnative from "webnative"
import { Maybe } from "webnative"
import { hasProp } from "webnative/common/index"
import { DistinctivePath, Partition, PartitionedNonEmpty } from "webnative/path/index"


export type Reference = string


/**
 * Create TaskPort namespace.
 */
export function createTaskPortNamespace(TaskPort) {
  return TaskPort.createNamespace("fission-codes/webnative", "8.1.0")
}


/**
 * Setup the ports for our Elm app.
 *
 * @param program Existing programs to
 */
export function init(options: {
  fileSystems?: Webnative.FileSystem[]
  programs?: Webnative.Program[],
  TaskPort: any
}): { taskPortNamespace } {
  const fileSystems: Record<string, Webnative.FileSystem> = Object.fromEntries(
    (options.fileSystems || []).map(fs => [ fileSystemRef(fs), fs ])
  )

  const programs: Record<string, Webnative.Program> = Object.fromEntries(
    (options.programs || []).map(program => [ programRef(program), program ])
  )

  const ns = createTaskPortNamespace(options.TaskPort)

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
  ns.register("fileSystem_write", withFs(addToFileSystem))

  return { taskPortNamespace: ns }
}



// TASKS


function addToFileSystem(fs: Webnative.FileSystem) {
  return (path: DistinctivePath<PartitionedNonEmpty<Partition>>, bytes: number[]) => fs.write(
    path, Uint8Array.from(bytes)
  )
}


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
  const fs = await program.fileSystem.load(username)
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
  fn: (fs: Webnative.FileSystem) => unknown
) {
  return async ({ arg, fileSystemRef, useSplat }) => {
    const fs = fileSystems[ fileSystemRef ]
    const innerValue = fn(fs)
    if (typeof innerValue !== "function") return innerValue
    const result = useSplat ? await innerValue.apply(fs, arg) : await innerValue.call(fs, arg)

    if (hasProp(result, "account")) return null // FileSystem instance
    if (hasProp(result, "code")) return result.toString()
    if (hasProp(result, "buffer")) return Array.from(result as Uint8Array)
    return result
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
    return useSplat ? innerValue.apply(program, arg) : innerValue.call(program, arg)
  }
}