;; SPDX-License-Identifier: PMPL-1.0-or-later
;; Hyperpolymath Security Standards (Canonical Reference)

(define user-security-requirements
  '(
    ;; Category, Algorithm/Standard, NIST/FIPS Standard, Notes
    (PasswordHashing "Argon2id (512 MiB, 8 iter, 4 lanes)" "—" "Max memory/iterations for GPU/ASIC resistance; aligns with proactive security stance.")
    (GeneralHashing "SHAKE3-512 (512-bit output)" "FIPS 202" "Post-quantum; use for provenance, key derivation, and long-term storage.")
    (PQSignatures "Dilithium5-AES (hybrid)" "ML-DSA-87 (FIPS 204)" "Hybrid with AES-256 for belt-and-suspenders security. SPHINCS+ as conservative backup.")
    (PQKeyExchange "Kyber-1024 + SHAKE256-KDF" "ML-KEM-1024 (FIPS 203)" "Kyber-1024 for KEM, SHAKE256 for key derivation. SPHINCS+ as backup.")
    (ClassicalSigs "Ed448 + Dilithium5 (hybrid)" "—" "Ed448 for classical compatibility; Dilithium5 for PQ. SPHINCS+ as backup. Terminate Ed25519/SHA-1 immediately.")
    (Symmetric "XChaCha20-Poly1305 (256-bit key)" "—" "Larger nonce space; 256-bit keys for quantum margin.")
    (KeyDerivation "HKDF-SHAKE512" "FIPS 202" "Post-quantum KDF; use with all secret key material.")
    (RNG "ChaCha20-DRBG (512-bit seed)" "SP 800-90Ar1" "CSPRNG for deterministic, high-entropy needs.")
    (UserFriendlyHashNames "Base32(SHAKE256(hash)) → Wordlist" "—" "Memorable, deterministic mapping (e.g., \"Gigantic-Giraffe-7\" for drivers).")
    (DatabaseHashing "BLAKE3 (512-bit) + SHAKE3-512" "—" "BLAKE3 for speed, SHAKE3-512 for long-term storage (semantic XML/ARIA tags).")
    (SemanticXMLGraphQL "Virtuoso (VOS) + SPARQL 1.2" "—" "Supports WCAG 2.3 AAA, ARIA, and formal verification for accessibility/compliance.")
    (VMExecution "GraalVM (with formal verification)" "—" "Aligns with preference for introspective, reversible design.")
    (ProtocolStack "QUIC + HTTP/3 + IPv6 (IPv4 disabled)" "—" "Terminate HTTP/1.1, IPv4, and SHA-1 per \"danger zone\" policy.")
    (Accessibility "WCAG 2.3 AAA + ARIA + Semantic XML" "—" "CSS-first, HTML-second; full compliance with accessibility requirements.")
    (Fallback "SPHINCS+" "—" "Conservative PQ backup for all hybrid classical+PQ systems; use if primary PQ algorithm is ever compromised.")
    (FormalVerification "Coq/Isabelle (for crypto primitives)" "—" "Proactive attestation and transparent logic per system design principles.")
  )
)

;; DNS Security Extensions
(define dns-security
  '(
    (DNSSEC "ECDSA P-256 + Ed448" "RFC 8080" "Dual algorithm for transition; migrate to post-quantum when standardized.")
    (DANE-TLSA "3 1 1 (SHA-256 cert hash)" "RFC 6698" "Certificate association for SMTP/HTTPS.")
    (CAA "letsencrypt.org + digicert.com" "RFC 8659" "Restrict certificate issuance; incident reporting enabled.")
    (SSHFP "SHA-256 fingerprints" "RFC 4255" "SSH fingerprint validation; terminate SHA-1.")
  )
)

;; HTTP Security Headers (Cloudflare Pages)
(define http-security-headers
  '(
    (HSTS "max-age=63072000; includeSubDomains; preload" "RFC 6797" "2-year HSTS preload.")
    (CSP "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'" "CSP Level 3" "Strict CSP; no external resources.")
    (X-Frame-Options "DENY" "RFC 7034" "Prevent clickjacking.")
    (X-Content-Type-Options "nosniff" "—" "Prevent MIME sniffing.")
    (Referrer-Policy "strict-origin-when-cross-origin" "—" "Minimal referrer leakage.")
    (Permissions-Policy "geolocation=(), camera=(), microphone=()" "—" "Disable unnecessary features.")
    (Cross-Origin-Embedder-Policy "require-corp" "—" "Isolate origin.")
    (Cross-Origin-Opener-Policy "same-origin" "—" "Prevent cross-origin access.")
  )
)

;; TLS Configuration
(define tls-requirements
  '(
    (MinVersion "TLS 1.3" "RFC 8446" "Terminate TLS 1.2 and below.")
    (Ciphersuites "TLS_AES_256_GCM_SHA384, TLS_CHACHA20_POLY1305_SHA256" "—" "Only AEAD ciphers; 256-bit keys.")
    (KeyExchange "X25519 + Kyber-1024 (hybrid PQ)" "—" "Hybrid classical+PQ key exchange.")
    (Certificates "Ed448 + Dilithium5 (hybrid)" "—" "Hybrid certificate signatures.")
    (OCSP "OCSP Must-Staple" "RFC 6961" "Force OCSP stapling; no soft-fail.")
  )
)

;; Cryptographic Deprecations (IMMEDIATE TERMINATION)
(define crypto-danger-zone
  '(
    (SHA-1 "TERMINATED" "Collision attacks; replace with SHAKE3-512 or BLAKE3.")
    (MD5 "TERMINATED" "Collision attacks; no security use.")
    (Ed25519 "MIGRATE TO Ed448" "Insufficient quantum margin; use Ed448 + Dilithium5.")
    (RSA "MIGRATE TO Ed448 + Dilithium5" "Quantum vulnerable; terminate all RSA usage.")
    (AES-128 "MIGRATE TO XChaCha20-Poly1305 (256-bit)" "Insufficient quantum margin.")
    (IPv4 "TERMINATED" "IPv6-only; disable IPv4 stack entirely.")
    (HTTP/1.1 "TERMINATED" "Migrate to HTTP/3 + QUIC.")
  )
)
