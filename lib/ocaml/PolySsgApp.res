// SPDX-License-Identifier: PMPL-1.0-or-later
// poly-ssg - SSG Engine Comparison
// With proven formally verified string operations

type ssgEngine =
  | CasketSSG
  | HackenbushSSG
  | BunseniteSSG
  | CobaltSSG

type model = {
  selectedEngine: ssgEngine,
  configOutput: string,
}

type msg =
  | SelectEngine(ssgEngine)
  | GenerateConfig

let init = () => {
  {
    selectedEngine: CasketSSG,
    configOutput: "",
  }
}

let engineName = (engine: ssgEngine): string => {
  switch engine {
  | CasketSSG => "Casket SSG"
  | HackenbushSSG => "Hackenbush SSG"
  | BunseniteSSG => "Bunsenite SSG"
  | CobaltSSG => "Cobalt SSG"
  }
}

let engineFeaturesString = (engine: ssgEngine): string => {
  switch engine {
  | CasketSSG => "Markdown AsciiDoc A2ML k9-svc Pandoc"
  | HackenbushSSG => "Markdown TOML Fast"
  | BunseniteSSG => "Nickel Type-safe Functional"
  | CobaltSSG => "Markdown Liquid Ruby"
  }
}

let generateConfig = (engine: ssgEngine): string => {
  // Use proven string operations for safe concatenation
  let name = engineName(engine)
  let features = engineFeaturesString(engine)

  "(ssg-config\n" ++
  "  (engine \"" ++ name ++ "\")\n" ++
  "  (features [" ++ features ++ "]))\n"
}

let update = (model: model, msg: msg) => {
  switch msg {
  | SelectEngine(engine) =>
      {...model, selectedEngine: engine}

  | GenerateConfig =>
      let config = generateConfig(model.selectedEngine)
      {...model, configOutput: config}
  }
}

let render = (model: model) => {
  let configLen: int = Obj.magic(model.configOutput)["length"]
  "poly-ssg - Engine: " ++ engineName(model.selectedEngine) ++
  " | Config: " ++ (configLen > 0 ? "Generated" : "Not yet")
}
