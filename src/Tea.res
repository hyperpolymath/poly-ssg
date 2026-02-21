// SPDX-License-Identifier: PMPL-1.0-or-later
// Minimal TEA (The Elm Architecture) implementation for PolyStack.
//
// This module provides a simplified, high-assurance implementation of 
// the TEA pattern, suitable for verified static site generation.

// COMMANDS: Side-effect descriptors (none implemented in the minimal core).
module Cmd = {
  type t<'msg> = unit
  let none = ()
  let msg = (_msg: 'msg) => ()
}

// SUBSCRIPTIONS: External event listeners.
module Sub = {
  type t<'msg> = unit
  let none = ()
}

// VIRTUAL DOM: Simplified HTML tree construction.
module Html = {
  type node
  type attribute

  @val external document: 'a = "document"
  @send external getElementById: ('a, string) => Js.Nullable.t<Dom.element> = "getElementById"
  @set external setInnerHTML: (Dom.element, string) => unit = "innerHTML"

  // ELEMENT FACTORY: Creates a tagged HTML element with attributes and children.
  let tag = (tagName: string, _attrs: array<attribute>, children: array<node>): node => {
    // RAW FFI: Joins child nodes into a single innerHTML string.
    let childrenHtml: string = %raw(`
      children.map(c => c).join('')
    `)
    Obj.magic(`<${tagName}>${childrenHtml}</${tagName}>`)
  }

  // DSL: Convenience functions for common HTML tags.
  let div = (attrs, children) => tag("div", attrs, children)
  let p = (attrs, children) => tag("p", attrs, children)
  let h2 = (attrs, children) => tag("h2", attrs, children)
  let pre = (attrs, children) => tag("pre", attrs, children)
  let code = (attrs, children) => tag("code", attrs, children)
}

// RUNTIME: Manages the application lifecycle and DOM mounting.
module App = {
  type program<'model, 'msg> = {
    init: unit => ('model, Cmd.t<'msg>),
    update: ('model, 'msg) => ('model, Cmd.t<'msg>),
    view: 'model => Html.node,
    subscriptions: 'model => Sub.t<'msg>,
  }

  // MOUNT: Attaches the TEA program to the page.
  let standardProgram = (program: program<'model, 'msg>) => {
    let (model, _cmd) = program.init()
    let html = program.view(model)

    // DOM INTEGRATION: Targets the #tea-app container.
    switch Html.document->Html.getElementById("tea-app")->Js.Nullable.toOption {
    | Some(el) => el->Html.setInnerHTML(Obj.magic(html))
    | None => Js.log("TEA mount point #tea-app not found")
    }
  }
}
