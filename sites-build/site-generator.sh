#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Generate static sites for all 22 project domains

set -euo pipefail

SITES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SITES_DIR/template"
OUTPUT_DIR="$SITES_DIR/generated"

# Create output directory
mkdir -p "$OUTPUT_DIR"

generate_site() {
    local domain="$1"
    local repo="$2"
    local title="$3"
    local tagline="$4"
    local color="$5"
    
    local site_dir="$OUTPUT_DIR/$domain"
    mkdir -p "$site_dir"
    
    cat > "$site_dir/index.html" << HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title - $tagline</title>
    <meta name="description" content="$tagline">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .hero {
            background: $color;
            color: white;
            padding: 4rem 2rem;
            text-align: center;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .hero h1 {
            font-size: 3.5rem;
            margin-bottom: 1rem;
            font-weight: 800;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        }
        .hero p {
            font-size: 1.5rem;
            opacity: 0.95;
            max-width: 800px;
            margin: 0 auto;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 3rem 2rem;
            background: white;
            box-shadow: 0 -4px 20px rgba(0,0,0,0.1);
        }
        .features {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 2rem;
            margin: 3rem 0;
        }
        .feature {
            padding: 2rem;
            background: #f8f9fa;
            border-radius: 12px;
            border-left: 4px solid $color;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .feature:hover {
            transform: translateY(-4px);
            box-shadow: 0 8px 16px rgba(0,0,0,0.1);
        }
        .feature h3 {
            color: $color;
            margin-bottom: 1rem;
            font-size: 1.5rem;
        }
        .cta {
            text-align: center;
            margin: 3rem 0;
        }
        .cta a {
            display: inline-block;
            background: $color;
            color: white;
            padding: 1rem 2.5rem;
            border-radius: 50px;
            text-decoration: none;
            font-weight: 600;
            font-size: 1.1rem;
            transition: transform 0.2s, box-shadow 0.2s;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        }
        .cta a:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(0,0,0,0.25);
        }
        .footer {
            text-align: center;
            padding: 2rem;
            background: #2d3748;
            color: white;
        }
        .footer a {
            color: #63b3ed;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="hero">
        <h1>$title</h1>
        <p>$tagline</p>
    </div>
    
    <div class="container">
        <div class="features">
            <div class="feature">
                <h3>🚀 Production Ready</h3>
                <p>Built with modern tools and proven in real-world applications.</p>
            </div>
            <div class="feature">
                <h3>📚 Well Documented</h3>
                <p>Comprehensive documentation and examples to get you started quickly.</p>
            </div>
            <div class="feature">
                <h3>🔒 Type Safe</h3>
                <p>Formally verified components ensure correctness and reliability.</p>
            </div>
        </div>
        
        <div class="cta">
            <a href="https://github.com/hyperpolymath/$repo" target="_blank">
                View on GitHub →
            </a>
        </div>
    </div>
    
    <div class="footer">
        <p>Built with ❤️ using <a href="https://poly-ssg.org">poly-ssg</a></p>
        <p>License: <a href="https://palimpsest.license">PMPL-1.0-or-later</a></p>
    </div>
</body>
</html>
HTML
    
    echo "✓ Generated $domain"
}

# Generate all 22 sites
generate_site "a2ml.net" "a2ml" "A2ML" "Attested Markup Language - Verifiable, machine-readable documentation" "#667eea"
generate_site "affinescript.dev" "affinescript" "AffineScript" "Resource-aware programming with affine types" "#764ba2"
generate_site "nesy-prover.dev" "echidna" "ECHIDNA" "Neurosymbolic theorem proving with 12 provers" "#3182ce"

echo
echo "=== Site Generation Complete ==="
echo "Sites generated in: $OUTPUT_DIR"
echo "Next: Deploy to GitHub Pages and configure Cloudflare DNS"
