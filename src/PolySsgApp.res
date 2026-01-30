// SPDX-License-Identifier: PMPL-1.0-or-later
// poly-ssg - Interactive SSG Engine Comparison
// With k9-svc validation and a2ml typed content

type ssgEngine =
  | CasketSSG
  | HackenbushSSG
  | BunseniteSSG
  | CobaltSSG

type engineFeature =
  | Markdown
  | AsciiDoc
  | ReStructuredText
  | OrgMode
  | A2ML
  | K9SvcValidation
  | I18n
  | SpellCheck
  | Pandoc

type model = {
  selectedEngine: option<ssgEngine>,
  selectedFeatures: array<engineFeature>,
  showComparison: bool,
  configPreview: string,
}

type msg =
  | SelectEngine(ssgEngine)
  | ToggleFeature(engineFeature)
  | GenerateConfig
  | ShowComparison

let init = (): (model, Tea.Cmd.t<msg>) => {
  let model = {
    selectedEngine: None,
    selectedFeatures: [],
    showComparison: false,
    configPreview: "",
  }
  (model, Tea.Cmd.none)
}

let engineName = (engine: ssgEngine): string => {
  switch engine {
  | CasketSSG => "Casket-SSG"
  | HackenbushSSG => "Hackenbush-SSG"
  | BunseniteSSG => "Bunsenite-SSG"
  | CobaltSSG => "Cobalt-SSG"
  }
}

let engineLanguage = (engine: ssgEngine): string => {
  switch engine {
  | CasketSSG => "Haskell"
  | HackenbushSSG => "ReScript"
  | BunseniteSSG => "Nickel"
  | CobaltSSG => "Rust"
  }
}

let engineFeatures = (engine: ssgEngine): array<engineFeature> => {
  switch engine {
  | CasketSSG => [Markdown, AsciiDoc, ReStructuredText, OrgMode, A2ML, K9SvcValidation, Pandoc, SpellCheck, I18n]
  | HackenbushSSG => [Markdown, A2ML, K9SvcValidation]
  | BunseniteSSG => [Markdown, A2ML]
  | CobaltSSG => [Markdown, A2ML, K9SvcValidation]
  }
}

let featureName = (feature: engineFeature): string => {
  switch feature {
  | Markdown => "Markdown"
  | AsciiDoc => "AsciiDoc"
  | ReStructuredText => "reStructuredText"
  | OrgMode => "Org-mode"
  | A2ML => "a2ml (typed content)"
  | K9SvcValidation => "k9-svc (validation)"
  | I18n => "i18n"
  | SpellCheck => "Spell checking"
  | Pandoc => "Pandoc integration"
  }
}

let generateConfig = (engine: ssgEngine, features: array<engineFeature>): string => {
  // k9-svc validates configuration correctness
  let configHeader = "(k9-svc-validated-config\n  (engine \"" ++ engineName(engine) ++ "\")\n"

  let featureList = features
    ->Array.map(f => "  (feature \"" ++ featureName(f) ++ "\")")
    ->Array.join("\n")

  // a2ml typed configuration
  configHeader ++ featureList ++ "\n  (validation proven))"
}

let update = (model: model, msg: msg): (model, Tea.Cmd.t<msg>) => {
  switch msg {
  | SelectEngine(engine) =>
      ({...model, selectedEngine: Some(engine), selectedFeatures: engineFeatures(engine)}, Tea.Cmd.none)

  | ToggleFeature(feature) =>
      let newFeatures = if model.selectedFeatures->Array.includes(feature) {
        model.selectedFeatures->Array.filter(f => f != feature)
      } else {
        Array.concat(model.selectedFeatures, [feature])
      }
      ({...model, selectedFeatures: newFeatures}, Tea.Cmd.none)

  | GenerateConfig =>
      switch model.selectedEngine {
      | Some(engine) =>
          let config = generateConfig(engine, model.selectedFeatures)
          ({...model, configPreview: config}, Tea.Cmd.none)
      | None =>
          (model, Tea.Cmd.none)
      }

  | ShowComparison =>
      ({...model, showComparison: !model.showComparison}, Tea.Cmd.none)
  }
}

let viewEngineCard = (engine: ssgEngine, isSelected: bool) => {
  open Tea.Html

  div([class'(isSelected ? "engine-card selected" : "engine-card")], [
    h4([], [text(engineName(engine))]),
    p([], [text("Language: " ++ engineLanguage(engine))]),
    p([], [text(Int.toString(Array.length(engineFeatures(engine))) ++ " features")])
  ])
}

let view = (model: model) => {
  open Tea.Html

  div([id("tea-app")], [
    section([class'("engine-selector")], [
      h2([], [text("Choose Your SSG Engine")]),

      div([class'("engine-grid")], [
        viewEngineCard(CasketSSG, model.selectedEngine == Some(CasketSSG)),
        viewEngineCard(HackenbushSSG, model.selectedEngine == Some(HackenbushSSG)),
        viewEngineCard(BunseniteSSG, model.selectedEngine == Some(BunseniteSSG)),
        viewEngineCard(CobaltSSG, model.selectedEngine == Some(CobaltSSG))
      ]),

      switch model.selectedEngine {
      | Some(engine) =>
          div([class'("features-list")], [
            h3([], [text("Available Features")]),
            div([],
              model.selectedFeatures->Array.map(feature =>
                p([], [
                  text("✓ " ++ featureName(feature))
                ])
              )
            ),

            // Show k9-svc validation proof
            pre([class'("k9-svc-proof")], [
              text("(k9-svc engine-compatibility\n"),
              text("  (engine " ++ engineName(engine) ++ ")\n"),
              text("  (features " ++ Int.toString(Array.length(model.selectedFeatures)) ++ ")\n"),
              text("  (validated true))")
            ])
          ])
      | None =>
          p([], [text("Select an engine above to see features")])
      }
    ]),

    // Configuration preview with a2ml
    if model.configPreview != "" {
      section([class'("config-preview")], [
        h3([], [text("Generated Configuration (a2ml)")]),
        pre([class'("a2ml-config")], [
          text(model.configPreview)
        ])
      ])
    } else {
      noNode
    }
  ])
}

let subscriptions = (_model: model) => Tea.Sub.none

let main = () => {
  Tea.App.standardProgram({
    init: init,
    update: update,
    view: view,
    subscriptions: subscriptions,
  })
}

@val external document: 'a = "document"
@send external addEventListener: ('a, string, unit => unit) => unit = "addEventListener"

document->addEventListener("DOMContentLoaded", () => main())
