// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

// Deno API bindings for ReScript

@scope("Deno") @val
external cwd: unit => string = "cwd"

module TextDecoder = {
  type t

  @new
  external make: unit => t = "TextDecoder"

  @send
  external decode: (t, Js.TypedArray2.Uint8Array.t) => string = "decode"
}

module Env = {
  @scope(("Deno", "env")) @val
  external get: string => option<string> = "get"

  @scope(("Deno", "env")) @val
  external set: (string, string) => unit = "set"
}

module Args = {
  @scope("Deno") @val
  external get: unit => array<string> = "args"
}

module Fs = {
  @scope("Deno") @val
  external readTextFile: string => promise<string> = "readTextFile"

  @scope("Deno") @val
  external writeTextFile: (string, string) => promise<unit> = "writeTextFile"

  @scope("Deno") @val
  external mkdir: (string, {"recursive": bool}) => promise<unit> = "mkdir"

  @scope("Deno") @val
  external remove: (string, {"recursive": bool}) => promise<unit> = "remove"

  type fileInfo = {
    isFile: bool,
    isDirectory: bool,
    size: float,
  }

  @scope("Deno") @val
  external stat: string => promise<fileInfo> = "stat"
}

module Command = {
  type t

  type output = {
    success: bool,
    code: int,
    stdout: Js.TypedArray2.Uint8Array.t,
    stderr: Js.TypedArray2.Uint8Array.t,
  }

  type commandOptions = {
    args: array<string>,
    cwd: string,
    stdout: string,
    stderr: string,
  }

  @new @scope("Deno")
  external make: (string, commandOptions) => t = "Command"

  @send
  external output: t => promise<output> = "output"

  // Helper to run a command and return decoded result
  let run = async (binary: string, args: array<string>, cwdPath: option<string>) => {
    let cmd = make(
      binary,
      {
        args,
        cwd: switch cwdPath {
        | Some(p) => p
        | None => cwd()
        },
        stdout: "piped",
        stderr: "piped",
      },
    )
    let result = await output(cmd)
    let decoder = TextDecoder.make()
    {
      Executor.success: result.success,
      stdout: TextDecoder.decode(decoder, result.stdout),
      stderr: TextDecoder.decode(decoder, result.stderr),
      code: result.code,
    }
  }
}
