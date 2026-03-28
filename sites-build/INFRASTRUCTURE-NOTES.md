# SPDX-License-Identifier: PMPL-1.0-or-later

# Hyperpolymath Sites Infrastructure

## Dogfooding Architecture (Leveraging Existing Tools)

### Core Components Already Available

#### 1. **rescript-dom-mounter** (High-Assurance DOM Mounting)
- **Location**: `~/Documents/hyperpolymath-repos/rescript-dom-mounter`
- **Purpose**: Safe, verified DOM manipulation
- **Use**: Mount interactive components (contact forms, galleries) with formal guarantees
- **Integration**: Import via Deno, compile ReScript → JS

#### 2. **Idris2 ABIs + Zig FFIs** (Formal Verification + Safe FFI)
- **ABIs**: `/var$REPOS_DIR/language-bridges/src/abi/*.idr`
- **FFIs**: `/var$REPOS_DIR/language-bridges/ffi/zig/src/*.zig`
- **Purpose**: Type-safe, formally verified interfaces
- **Use**: Generate crypto primitives (SHAKE3-512, Kyber-1024, Dilithium5) with proofs

#### 3. **feedback-o-tron** (Feedback Mechanism)
- **Purpose**: Unified feedback system
- **Use**: Replace placeholder contact forms with verified feedback pipeline
- **Features**: Email validation, spam filtering, A2ML attestation

#### 4. **k9-svc** (Service Orchestration)
- **Location**: `contractiles/k9/k9-svc`
- **Purpose**: Orchestrate site services (build, deploy, monitor)
- **Use**: Automate site generation, DNS updates, certificate renewal
- **Integration**: Systemd service + cron for automated rebuilds

#### 5. **A2ML (Attested Markup Language)**
- **Purpose**: Verifiable, machine-readable documentation
- **Use**: Generate `.well-known/aibdp.json` with cryptographic attestation
- **Features**: SHAKE3-512 signatures, provenance tracking, version control

### Security Primitive Integration

#### Cryptographic Libraries (Already Available)
```
language-bridges/
├── src/abi/Crypto.idr          # Formal crypto ABIs
├── ffi/zig/src/shake3.zig      # SHAKE3-512 implementation
├── ffi/zig/src/kyber.zig       # Kyber-1024 KEM
├── ffi/zig/src/dilithium.zig   # Dilithium5 signatures
└── ffi/zig/src/sphincs.zig     # SPHINCS+ fallback
```

#### WCAG Compliance (consent-aware-http)
```
consent-aware-http/
├── spec/                       # HTTP 430 specification
├── .well-known/aibdp.schema    # AIBDP JSON schema
└── examples/                   # Example implementations
```

### Enhanced Site Generation Pipeline

#### Current Pipeline
```
build-all-sites.sh → generators/*.sh → generated/{domain}/
```

#### Enhanced Pipeline (Dogfooding)
```
1. k9-svc orchestrate build
2. A2ML generate attested metadata
3. Idris2 verify crypto primitives
4. Zig FFI execute cryptographic operations
5. rescript-dom-mounter compile interactive components
6. feedback-o-tron wire up contact forms
7. consent-aware-http validate AIBDP compliance
8. Generate static sites with embedded verification proofs
```

### Next Steps (Leveraging Existing Tools)

#### Phase 1: Enhance Static Sites
- [ ] Replace placeholder contact forms with **feedback-o-tron**
- [ ] Add **rescript-dom-mounter** for interactive galleries
- [ ] Generate **A2ML** attestations for all metadata
- [ ] Add crypto verification badges (SHAKE3-512 hashes displayed)

#### Phase 2: Security Hardening
- [ ] Generate TLSA hashes using **Zig FFI** (SHAKE3-512)
- [ ] Create SSH Ed448 keys via **Idris2 ABI**
- [ ] Sign DNS zone files with **Dilithium5** (hybrid with Ed448)
- [ ] Deploy **SPHINCS+** signatures as fallback

#### Phase 3: Automation
- [ ] Configure **k9-svc** for nightly site rebuilds
- [ ] Add **dust-svc** (from contractiles) for drift detection
- [ ] Integrate **lust-svc** for liveness checks (HTTP 430 compliance)
- [ ] Use **trust-svc** for certificate renewal automation

#### Phase 4: Formal Verification
- [ ] Verify **rescript-dom-mounter** with Coq proofs
- [ ] Validate crypto primitives with Isabelle/HOL
- [ ] Generate accessibility attestations (WCAG 2.3 AAA compliance proofs)
- [ ] Create A2ML documents with formal verification certificates

### Integration Examples

#### Contact Form (feedback-o-tron)
```rescript
// Import from feedback-o-tron repo
open FeedbackOTron

let contactForm = FeedbackForm.create(
  ~validation=A2MLValidator.create(),
  ~crypto=SHAKE3_512.hash,
  ~destination="https://hyperpolymath.org/api/feedback",
  ~attestation=true
)

// Mount with rescript-dom-mounter
DomMounter.mount(contactForm, "#contact-form")
```

#### AIBDP Generation (A2ML)
```julia
# Generate attested AIBDP with A2ML
using A2ML

aibdp = AIBDP(
    version="1.0",
    site=Site(name="7tentacles", domain="7tentacles.org"),
    consent=Consent(ai_training=true, attribution_required=true),
    crypto_standards=CryptoStandards(
        hash="SHAKE3-512",
        signature="Dilithium5+Ed448",
        fallback="SPHINCS+"
    )
)

# Sign with Dilithium5
signature = sign_dilithium5(serialize(aibdp))

# Generate A2ML document
a2ml_doc = A2ML.create(aibdp, signature)
write(".well-known/aibdp.a2ml", a2ml_doc)
```

#### Crypto Verification Badge
```html
<!-- Display verification proof on each page -->
<footer>
  <div class="crypto-verification">
    <p>🔒 Cryptographically Verified</p>
    <ul>
      <li><strong>Hash:</strong> SHAKE3-512(<code id="page-hash"></code>)</li>
      <li><strong>Signature:</strong> Dilithium5+Ed448 <a href="/verification.proof">Verify</a></li>
      <li><strong>Fallback:</strong> SPHINCS+ available</li>
    </ul>
  </div>
</footer>

<script type="module">
import { verifyPage } from '/assets/rescript-dom-mounter.js';
verifyPage(document.body).then(hash => {
  document.getElementById('page-hash').textContent = hash;
});
</script>
```

### DNS + Crypto Integration

#### TLSA Hash Generation (Zig FFI)
```bash
# Use Zig FFI to generate TLSA hashes
cd ~/Documents/hyperpolymath-repos/language-bridges/ffi/zig
zig build
./build/bin/tlsa-hash --cert=/path/to/cert.pem --algorithm=SHAKE3-512
```

#### SSH Fingerprint (Idris2 ABI)
```idris
-- Generate Ed448 SSH fingerprint with formal proof
module SSHFingerprint

import Crypto.Ed448
import Crypto.SHAKE3

export
generateFingerprint : Ed448PublicKey -> SSHFP
generateFingerprint pubkey =
  let hash = SHAKE3.hash512 (encode pubkey)
  in SSHFP (algorithm=6) (digestType=2) hash
```

## References

- `SECURITY-STANDARDS.scm` - Canonical crypto requirements
- `dns-zones/template.zone` - DNS template with DANE/TLSA
- `generators/` - Site generation scripts
- `wellknown-templates/` - .well-known/ file templates

## Tools to Integrate

1. **rescript-dom-mounter** - DOM mounting
2. **feedback-o-tron** - Feedback forms
3. **k9-svc** - Service orchestration
4. **A2ML** - Attested markup
5. **Idris2 ABIs** - Formal crypto specs
6. **Zig FFIs** - Safe crypto implementations
7. **consent-aware-http** - HTTP 430 compliance
8. **cadre-tea-router** - Verified routing (already planned for TEA apps)
9. **rescript-tea** - Elm Architecture framework (for interactive sites)

## Status

- ✅ Static site generation (10/22 sites)
- ✅ WCAG 2.3 AA/AAA compliance
- ✅ Security headers + .well-known/
- ✅ DNS zone templates (22/22)
- ✅ Ethical policies (anti-slavery, AML, data sovereignty)
- 🔲 Integration with existing hyperpolymath tools
- 🔲 Crypto verification proofs
- 🔲 A2ML attestations
- 🔲 k9-svc automation
- 🔲 Complete remaining 12 sites
