# SPDX-License-Identifier: AGPL-3.0-or-later
# K9 Contractile: Kennel Level (Pure Data)
# Project metadata for poly-ssg

{
  leash = 'Kennel,

  project = {
    name = "poly-ssg",
    version = "1.0.0",
    description = "Interactive comparison of Static Site Generators with proven validation",
    homepage = "https://poly-ssg.org",
    repository = "https://github.com/hyperpolymath/poly-ssg",

    license = "AGPL-3.0-or-later",
    author = {
      name = "Jonathan D.A. Jewell",
      email = "jonathan.jewell@open.ac.uk",
    },

    keywords = [
      "static-site-generator",
      "ssg-comparison",
      "casket-ssg",
      "hackenbush-ssg",
      "bunsenite-ssg",
      "rescript",
      "proven",
    ],
  },

  tech_stack = {
    languages = ["ReScript", "JavaScript", "HTML", "CSS"],
    runtime = "Deno",
    libraries = [
      "rescript-tea",
      "rescript-dom-mounter",
      "proven",
      "cadre-tea-router",
    ],

    build_tools = ["ReScript", "Deno"],
    package_manager = "Deno",
  },

  deployment = {
    platform = "Cloudflare Pages",
    domain = "poly-ssg.org",
    build_command = "deno task build",
    output_directory = "/",
  },

  features = {
    proven_validation = true,
    formal_verification = true,
    tea_architecture = true,
    ssg_comparison = true,
    interactive_demo = true,
    dom_mounting = "rescript-dom-mounter",
  },

  status = {
    phase = "MVP Development",
    completion_percentage = 60,
    production_ready = false,
  },
}
