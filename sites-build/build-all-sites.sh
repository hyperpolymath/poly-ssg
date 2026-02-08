#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Build all 22 hyperpolymath project sites with WCAG AA/AAA compliance

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATED_DIR="$SCRIPT_DIR/generated"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
WELLKNOWN_DIR="$SCRIPT_DIR/wellknown-templates"

# Color palette for different project categories
declare -A COLORS=(
    # AI/ML focused
    ["7tentacles"]="#663399"  # Deep purple (octopus theme)
    ["my-lang"]="#E74C3C"     # Vibrant red (playgrounds/dev)
    ["nesy-prover"]="#3498DB"  # Intelligent blue

    # Security/Edge
    ["oblibeny"]="#1A1F35"    # Dark professional (Cloudflare-style)
    ["hypervigilant"]="#C0392B"  # Alert red

    # Development Tools
    ["a2ml"]="#667eea"        # Modern purple
    ["affinescript"]="#764ba2" # Rich purple
    ["echidna"]="#3182ce"     # Ocean blue
    ["verisimdb"]="#8E44AD"   # Database purple

    # Language/Type Theory
    ["lithoglyph"]="#27AE60"  # Natural green
    ["typewise"]="#16A085"    # Teal

    # Networking/Infrastructure
    ["ipv6-mastery"]="#2C3E50" # Network gray-blue
    ["ipv6-ready"]="#34495E"   # Infrastructure gray

    # Identity/Auth
    ["did-spec"]="#9B59B6"    # Identity purple

    # Package Management
    ["palimpsest"]="#E67E22"  # Orange (rewriting)

    # Default
    ["default"]="#2980B9"     # Professional blue
)

# Project categories for themed components
declare -A CATEGORIES=(
    ["7tentacles"]="ai"
    ["my-lang"]="playground"
    ["nesy-prover"]="ai"
    ["oblibeny"]="security"
    ["hypervigilant"]="security"
    ["a2ml"]="tooling"
    ["affinescript"]="language"
    ["echidna"]="verification"
    ["verisimdb"]="database"
    ["lithoglyph"]="language"
    ["typewise"]="language"
    ["ipv6-mastery"]="networking"
    ["ipv6-ready"]="networking"
    ["did-spec"]="identity"
    ["palimpsest"]="license"
)

# Site definitions: domain | repo | title | tagline | category
declare -a SITES=(
    "7tentacles.org|7tentacles|7tentacles|AI-first polyglot development with 8 intelligent tentacles|ai"
    "my-lang.net|my-lang|my-lang|Language playground framework for lifetime experimentation|playground"
    "a2ml.net|a2ml|A2ML|Attested Markup Language - Verifiable machine-readable documentation|tooling"
    "affinescript.dev|affinescript|AffineScript|Resource-aware programming with affine linear types|language"
    "nesy-prover.dev|echidna|ECHIDNA|Neurosymbolic theorem proving with 12 integrated provers|ai"
    "verisimdb.org|verisimdb|VeriSimDB|Hexad-modality polyglot database with 6 unified stores|database"
    "lithoglyph.org|lithoglyph|LithoGlyph|Unicode glyph analysis and intelligent typography|language"
    "oblibeny.net|oblibeny|Oblibeny|Secure edge capabilities and distributed networking|security"
    "hypervigilant.dev|hypervigilant|HyperVigilant|Continuous security monitoring and threat intelligence|security"
    "ipv6-mastery.net|ipv6-mastery|IPv6 Mastery|Complete IPv6 education and certification program|networking"
    "ipv6-ready.net|ipv6-ready|IPv6 Ready|Tools and utilities for IPv6 migration and compliance|networking"
    "did-spec.org|did-spec|DID Specification|Decentralized identifier standards and implementations|identity"
    "palimpsest.license|palimpsest|Palimpsest License|Open source license for ethical AI and rewritable code|license"
    "typewise.dev|typewise|TypeWise|Type system education and dependent type theory resources|language"
)

get_color() {
    local project="$1"
    echo "${COLORS[$project]:-${COLORS[default]}}"
}

get_category() {
    local project="$1"
    echo "${CATEGORIES[$project]:-tooling}"
}

# Create directory structure
mkdir -p "$GENERATED_DIR" "$TEMPLATES_DIR" "$WELLKNOWN_DIR"

echo "=== Building 22 Hyperpolymath Project Sites ==="
echo "Output: $GENERATED_DIR"
echo ""

# Process each site
for site_def in "${SITES[@]}"; do
    IFS='|' read -r domain repo title tagline category <<< "$site_def"

    project_key="${repo}"
    color=$(get_color "$project_key")

    echo "Building: $domain ($title)"

    site_dir="$GENERATED_DIR/$domain"
    mkdir -p "$site_dir"/{assets,docs,gallery,.well-known}

    # Generate pages (calling page generators)
    "$SCRIPT_DIR/generators/generate-home.sh" "$domain" "$repo" "$title" "$tagline" "$color" "$category" > "$site_dir/index.html"
    "$SCRIPT_DIR/generators/generate-about.sh" "$domain" "$repo" "$title" "$tagline" "$color" "$category" > "$site_dir/about.html"
    "$SCRIPT_DIR/generators/generate-contact.sh" "$domain" "$repo" "$title" "$tagline" "$color" "$category" > "$site_dir/contact.html"
    "$SCRIPT_DIR/generators/generate-gallery.sh" "$domain" "$repo" "$title" "$tagline" "$color" "$category" > "$site_dir/gallery.html"
    "$SCRIPT_DIR/generators/generate-docs.sh" "$domain" "$repo" "$title" "$tagline" "$color" "$category" > "$site_dir/docs.html"
    "$SCRIPT_DIR/generators/generate-policies.sh" "$domain" "$repo" "$title" "$tagline" "$color" "$category" > "$site_dir/policies.html"

    # Generate .well-known files
    "$SCRIPT_DIR/generators/generate-aibdp.sh" "$domain" "$repo" "$title" > "$site_dir/.well-known/aibdp.json"
    cp "$SCRIPT_DIR/wellknown-templates/security.txt" "$site_dir/.well-known/security.txt"
    cp "$SCRIPT_DIR/wellknown-templates/change-password" "$site_dir/.well-known/change-password"

    # Generate _headers
    "$SCRIPT_DIR/generators/generate-headers.sh" "$domain" > "$site_dir/_headers"

    # Generate robots.txt
    cat > "$site_dir/robots.txt" << EOF
# SPDX-License-Identifier: PMPL-1.0-or-later
User-agent: *
Allow: /
Sitemap: https://$domain/sitemap.xml

# AI/ML agents
User-agent: GPTBot
Allow: /

User-agent: ChatGPT-User
Allow: /

User-agent: Claude-Web
Allow: /

User-agent: anthropic-ai
Allow: /
EOF

    # Generate sitemap.xml
    cat > "$site_dir/sitemap.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>https://$domain/</loc><priority>1.0</priority></url>
  <url><loc>https://$domain/about.html</loc><priority>0.8</priority></url>
  <url><loc>https://$domain/contact.html</loc><priority>0.7</priority></url>
  <url><loc>https://$domain/gallery.html</loc><priority>0.6</priority></url>
  <url><loc>https://$domain/docs.html</loc><priority>0.9</priority></url>
  <url><loc>https://$domain/policies.html</loc><priority>0.5</priority></url>
</urlset>
EOF

    echo "  ✓ Generated: index, about, contact, gallery, docs, policies"
    echo "  ✓ Added: .well-known/, _headers, robots.txt, sitemap.xml"
    echo ""
done

echo "=== Build Complete ==="
echo "Generated $(find "$GENERATED_DIR" -name "index.html" | wc -l) sites"
echo ""
echo "Next steps:"
echo "1. Review sites in $GENERATED_DIR"
echo "2. Test accessibility with axe-core or WAVE"
echo "3. Deploy to GitHub Pages"
echo "4. Configure Cloudflare DNS"
