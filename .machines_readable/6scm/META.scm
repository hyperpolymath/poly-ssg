;; SPDX-License-Identifier: MPL-2.0-or-later
;; META.scm - poly-ssg meta information

(define meta
  (architecture-decisions
    (adr "adr-001"
      (status "accepted")
      (date "2026-01-30")
      (context "Need safe config generation for SSG comparisons")
      (decision "Use ProvenSafeString for formally verified string operations")
      (consequences "Config generation cannot fail at runtime"))

    (adr "adr-002"
      (status "accepted")
      (date "2026-01-30")
      (context "Array operations unavailable in minimal ReScript setup")
      (decision "Use %raw JavaScript for array operations or manual concatenation")
      (consequences "Trade type safety for compilation simplicity")))

  (development-practices
    (code-style "ReScript conventions, minimal Obj.magic usage")
    (security "CSP headers, HTTPS-only, proven validation")
    (testing "Property tests via proven library"))

  (design-rationale
    (why-rescript "Type safety, fast compilation, JS interop")
    (why-deno "RSR policy, modern runtime, explicit permissions")
    (why-proven "Demonstrate formal verification in web apps")
    (why-tea "Predictable state, testable logic")))
