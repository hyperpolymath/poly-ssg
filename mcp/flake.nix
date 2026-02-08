# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 hyperpolymath
{
  description = "Polyglot SSG MCP - MCP server for 29 static site generators";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # SSGs available in Nix
        ssgPackages = with pkgs; [
          # Rust SSGs
          zola
          mdbook
          # cobalt  # if available

          # Haskell SSGs
          haskellPackages.hakyll

          # Other SSGs
          hugo  # Go-based but widely used
        ];

      in {
        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Runtime
            deno

            # ReScript build
            nodejs_20

            # Development tools
            just
            jq

            # Optional: SSGs for local testing
          ] ++ ssgPackages;

          shellHook = ''
            export DENO_DIR=$PWD/.deno
            echo "Polyglot SSG MCP development environment"
            echo ""
            echo "Commands:"
            echo "  deno task start     - Start MCP server (stdio)"
            echo "  deno task serve     - Start HTTP server"
            echo "  deno task dev       - Start with file watching"
            echo "  deno task res:build - Build ReScript"
            echo ""
            echo "Supported SSGs: 29 across 20 languages"
          '';
        };

        # Package for running the MCP server
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "poly-ssg-mcp";
          version = "1.1.0";

          src = ./.;

          nativeBuildInputs = with pkgs; [ deno nodejs_20 ];

          buildPhase = ''
            export HOME=$TMPDIR
            export DENO_DIR=$TMPDIR/.deno

            # Install npm deps for ReScript
            npm install

            # Build ReScript
            npx rescript build

            # Cache Deno dependencies
            deno cache --config=deno.json main.js
          '';

          installPhase = ''
            mkdir -p $out/lib/poly-ssg-mcp
            mkdir -p $out/bin

            # Copy source files
            cp -r lib $out/lib/poly-ssg-mcp/
            cp main.js $out/lib/poly-ssg-mcp/
            cp deno.json $out/lib/poly-ssg-mcp/

            # Create wrapper script
            cat > $out/bin/poly-ssg-mcp << EOF
            #!/bin/sh
            exec ${pkgs.deno}/bin/deno run \
              --allow-run --allow-read --allow-write --allow-env --allow-net \
              --config=$out/lib/poly-ssg-mcp/deno.json \
              $out/lib/poly-ssg-mcp/main.js "\$@"
            EOF
            chmod +x $out/bin/poly-ssg-mcp
          '';

          meta = with pkgs.lib; {
            description = "MCP server for 29 static site generators";
            homepage = "https://github.com/hyperpolymath/poly-ssg-mcp";
            license = licenses.mit;
            mainProgram = "poly-ssg-mcp";
          };
        };

        # HTTP server variant
        packages.http = pkgs.stdenv.mkDerivation {
          pname = "poly-ssg-mcp-http";
          version = "1.1.0";

          src = self.packages.${system}.default;

          installPhase = ''
            mkdir -p $out/lib $out/bin
            cp -r $src/lib/poly-ssg-mcp $out/lib/

            cat > $out/bin/poly-ssg-mcp-http << EOF
            #!/bin/sh
            export MCP_HTTP_MODE=true
            exec ${pkgs.deno}/bin/deno run \
              --allow-run --allow-read --allow-write --allow-env --allow-net \
              --config=$out/lib/poly-ssg-mcp/deno.json \
              $out/lib/poly-ssg-mcp/main.js "\$@"
            EOF
            chmod +x $out/bin/poly-ssg-mcp-http
          '';

          meta = with pkgs.lib; {
            description = "HTTP variant of Polyglot SSG MCP server";
            homepage = "https://github.com/hyperpolymath/poly-ssg-mcp";
            license = licenses.mit;
            mainProgram = "poly-ssg-mcp-http";
          };
        };

        # Development shell with all SSGs
        devShells.full = pkgs.mkShell {
          buildInputs = with pkgs; [
            deno
            nodejs_20
            just
            jq
          ] ++ ssgPackages;

          shellHook = ''
            export DENO_DIR=$PWD/.deno
            echo "Full SSG development environment with multiple SSGs installed"
          '';
        };
      }
    );
}
