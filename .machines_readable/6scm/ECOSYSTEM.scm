;; SPDX-License-Identifier: MPL-2.0-or-later
;; ECOSYSTEM.scm - poly-ssg ecosystem relationships

(ecosystem
  (version "1.0.0")
  (name "poly-ssg")
  (type "comparison-site")
  (purpose "Interactive comparison of SSG engines with formally verified config generation")

  (position-in-ecosystem
    "Demonstrates ReScript+Deno+proven stack"
    "Part of 4-site proven integration showcase"
    "Educational tool for SSG engine selection")

  (related-projects
    (project "rescript-tea" (relationship "sibling-standard"))
    (project "proven" (relationship "sibling-standard"))
    (project "stamp-website" (relationship "sibling-standard"))
    (project "asdf-plugins" (relationship "sibling-standard"))
    (project "axel-protocol" (relationship "sibling-standard"))
    (project "casket-ssg" (relationship "potential-consumer"))
    (project "poly-ssg-mcp" (relationship "potential-consumer")))

  (what-this-is
    "SSG engine comparison site"
    "Built with proven formally verified components"
    "ReScript+Deno stack demonstration")

  (what-this-is-not
    "NOT the poly-ssg framework itself"
    "NOT an SSG implementation"
    "NOT using Node.js (Deno per RSR)"))
