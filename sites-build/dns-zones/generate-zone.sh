#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Generate Cloudflare DNS zone files for all 22 domains

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/template.zone"
OUTPUT_DIR="$SCRIPT_DIR/generated"

mkdir -p "$OUTPUT_DIR"

# Serial number: YYYYMMDDNN
SERIAL=$(date +%Y%m%d)01

generate_zone() {
    local domain="$1"
    local repo="$2"
    local output="$OUTPUT_DIR/${domain}.zone"

    # Generate placeholder hashes (MUST UPDATE with real values before deployment)
    local tlsa_hash="PLACEHOLDER_TLSA_SHA256_HASH_UPDATE_BEFORE_DEPLOYMENT"
    local ssh_hash="PLACEHOLDER_SSH_ED448_SHA256_UPDATE_BEFORE_DEPLOYMENT"
    local github_challenge="PLACEHOLDER_GITHUB_VERIFICATION_CODE"
    local mta_sts_id=$(date +%Y%m%d%H)

    # Replace placeholders
    sed -e "s/{{DOMAIN}}/$domain/g" \
        -e "s/{{PROJECT}}/${repo}/g" \
        -e "s/{{REPO}}/${repo}/g" \
        -e "s/{{SERIAL}}/${SERIAL}/g" \
        -e "s/{{TLSA_HASH}}/${tlsa_hash}/g" \
        -e "s/{{SSH_ED448_SHA256}}/${ssh_hash}/g" \
        -e "s/{{GITHUB_CHALLENGE}}/${github_challenge}/g" \
        -e "s/{{MTA_STS_ID}}/${mta_sts_id}/g" \
        "$TEMPLATE" > "$output"

    echo "Generated: $output"
}

# All 22 domains
declare -a DOMAINS=(
    "7tentacles.org:7tentacles"
    "my-lang.net:my-lang"
    "a2ml.net:a2ml"
    "affinescript.dev:affinescript"
    "nesy-prover.dev:echidna"
    "verisimdb.org:verisimdb"
    "lithoglyph.org:lithoglyph"
    "oblibeny.net:oblibeny"
    "hypervigilant.dev:hypervigilant"
    "ipv6-mastery.net:ipv6-mastery"
    "ipv6-ready.net:ipv6-ready"
    "did-spec.org:did-spec"
    "palimpsest.license:palimpsest"
    "typewise.dev:typewise"
    "poly-ssg.org:poly-ssg"
    "scaffoldia.dev:scaffoldia"
    "polymono.dev:polymono"
    "http-capability-gateway.net:http-capability-gateway"
    "consent-aware-http.org:consent-aware-http"
    "cadre-tea-router.dev:cadre-tea-router"
    "rescript-tea.dev:rescript-tea"
    "gitbot-fleet.dev:gitbot-fleet"
)

echo "=== Generating DNS Zone Files ==="
echo "Output: $OUTPUT_DIR"
echo ""

for domain_def in "${DOMAINS[@]}"; do
    IFS=':' read -r domain repo <<< "$domain_def"
    generate_zone "$domain" "$repo"
done

echo ""
echo "=== Generation Complete ==="
echo "Generated $(ls -1 "$OUTPUT_DIR"/*.zone 2>/dev/null | wc -l) zone files"
echo ""
echo "⚠️  IMPORTANT: Before deployment, update placeholders:"
echo "  - TLSA hashes (from Let's Encrypt certificates)"
echo "  - SSH Ed448 fingerprints"
echo "  - GitHub verification codes"
echo "  - Cloudflare Pages IPv6 addresses"
echo ""
echo "See SECURITY-STANDARDS.scm for crypto requirements."
