#!/bin/bash
# SPDX-License-Identifier: MPL-2.0-or-later
# Output Validation Script
# Heuristic checks for selected unsafe output patterns; not a complete HTML/XSS validator.
#
# Usage: validate-output.sh <html-file>
#        validate-output.sh <directory>

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

log_error() { printf '%b[ERROR]%b %s\n' "$RED" "$NC" "$*"; ERRORS=$((ERRORS + 1)); }
log_warn() { printf '%b[WARN]%b %s\n' "$YELLOW" "$NC" "$*"; WARNINGS=$((WARNINGS + 1)); }
log_ok() { echo -e "${GREEN}[OK]${NC} $*"; }

validate_file() {
    local file="$1"
    local filename
    filename=$(basename -- "$file")

    echo "Validating: $filename"

    # Check file exists and is not empty
    if [[ ! -f "$file" || ! -r "$file" ]]; then
        log_error "File missing or unreadable: $file"
        return 0
    fi

    if [[ ! -s "$file" ]]; then
        log_error "File is empty: $file"
        return 0
    fi

    # Bash strings cannot contain NUL; check the file before command substitution.
    local nul_count
    nul_count=$(LC_ALL=C tr -cd '\000' < "$file" | wc -c)
    if (( nul_count > 0 )); then
        log_error "$filename: Contains null bytes"
        return 0
    fi

    # =========================================================================
    # SECURITY CHECKS - These are ERRORS (treat as failures)
    # =========================================================================

    # Check for unescaped script tags
    if grep -qi '<script[^>]*>' "$file"; then
        log_error "$filename: Contains <script> tag - potential XSS"
    fi

    # Check for event handlers
    if grep -Eqi 'on(click|load|error|mouseover|focus|blur|submit|change|keyup|keydown)[[:space:]]*=' "$file"; then
        log_error "$filename: Contains event handler attribute - potential XSS"
    fi

    # Check for javascript: URLs
    if grep -qi 'javascript:' "$file"; then
        log_error "$filename: Contains javascript: URL - potential XSS"
    fi

    # Check for data: URLs in dangerous contexts
    if grep -Eqi '(src|href)=["\x27]data:' "$file"; then
        log_warn "$filename: Contains data: URL - review for safety"
    fi

    # Check for path traversal in paths
    if grep -Eqi '(src|href)=["\x27][^"]*\.\./' "$file"; then
        log_error "$filename: Contains path traversal sequence"
    fi

    # Check for shell metacharacters that might indicate injection
    if grep -Eqi '\$\(|`[^`]*`|\$\{' "$file"; then
        log_warn "$filename: Contains shell-like syntax - verify escaping"
    fi

    # =========================================================================
    # HTML VALIDITY CHECKS
    # =========================================================================

    # Check for balanced tags (basic check)
    local open_tags close_tags
    open_tags=$(awk '{ while (match($0, /<(p|div|span|ul|ol|li|h[1-6]|blockquote|pre|code|table|tr|td|th|thead|tbody)([[:space:]][^>]*)?>/)) { n++; $0=substr($0,RSTART+RLENGTH) } } END { print n+0 }' "$file")
    close_tags=$(awk '{ while (match($0, /<\/(p|div|span|ul|ol|li|h[1-6]|blockquote|pre|code|table|tr|td|th|thead|tbody)>/)) { n++; $0=substr($0,RSTART+RLENGTH) } } END { print n+0 }' "$file")

    if [[ $open_tags -ne $close_tags ]]; then
        log_warn "$filename: Tag balance mismatch (open: $open_tags, close: $close_tags)"
    fi

    # Check for DOCTYPE and html structure
    if grep -qi '<!DOCTYPE' "$file"; then
        if ! grep -qi '<html' "$file"; then
            log_warn "$filename: Has DOCTYPE but no <html> tag"
        fi
        if ! grep -qi '<head' "$file"; then
            log_warn "$filename: Has DOCTYPE but no <head> tag"
        fi
        if ! grep -qi '<body' "$file"; then
            log_warn "$filename: Has DOCTYPE but no <body> tag"
        fi
    fi

    # =========================================================================
    # ENCODING CHECKS
    # =========================================================================

    # Check for proper UTF-8 (no invalid sequences)
    if ! iconv -f UTF-8 -t UTF-8 "$file" > /dev/null 2>&1; then
        log_error "$filename: Invalid UTF-8 encoding"
    fi

    # =========================================================================
    # ACCESSIBILITY CHECKS
    # =========================================================================

    # Check images have alt text
    if grep -qiE '<img[^>]+>' "$file" && ! grep -qiE '<img[^>]+alt=' "$file"; then
        log_warn "$filename: Image without alt attribute"
    fi

    # Check links have content
    if grep -qiE '<a[^>]*></a>' "$file"; then
        log_warn "$filename: Empty link found"
    fi

    return 0
}

# Main
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <file-or-directory>"
    exit 1
fi

TARGET="$1"

if [[ -d "$TARGET" ]]; then
    files=$(mktemp)
    trap 'rm -f -- "$files"' EXIT
    find "$TARGET" -name "*.html" -type f -print0 > "$files"
    if [[ ! -s "$files" ]]; then
        log_error "No HTML files found: $TARGET"
    fi
    while IFS= read -r -d '' file; do
        validate_file "$file"
    done < "$files"
elif [[ -f "$TARGET" ]]; then
    validate_file "$TARGET"
else
    echo "Error: $TARGET not found"
    exit 1
fi

echo ""
echo "Validation complete: $ERRORS errors, $WARNINGS warnings"

# Exit with error if any errors found
if [[ $ERRORS -gt 0 ]]; then
    exit 1
fi

# Exit with warning status if only warnings
if [[ $WARNINGS -gt 0 ]]; then
    exit 2
fi

exit 0

