# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
#
# Containerfile - works with podman, nerdctl, docker, buildah
# Uses official Deno image (distroless-based, minimal attack surface)

FROM denoland/deno:2.1.4

LABEL org.opencontainers.image.title="poly-ssg-mcp"
LABEL org.opencontainers.image.description="Unified MCP server for 28 static site generators"
LABEL org.opencontainers.image.authors="Jonathan D.A. Jewell"
LABEL org.opencontainers.image.source="https://github.com/hyperpolymath/poly-ssg-mcp"
LABEL org.opencontainers.image.licenses="MIT"
LABEL io.modelcontextprotocol.server.name="io.github.hyperpolymath/poly-ssg-mcp"

WORKDIR /app

# Copy compiled ReScript output and source files
COPY main.js index.js server.js deno.json ./
COPY lib/ ./lib/
COPY transport/ ./transport/
# src/ contains ReScript source (optional, for debugging)
COPY src/ ./src/

# Cache dependencies using deno.json config
RUN deno cache --config=deno.json main.js

# Create non-root user
RUN addgroup --system polyglot && adduser --system --ingroup polyglot polyglot
USER polyglot

# SSG CLIs expected to be available via volume mount or installed in derived image
# Example: podman run -v /usr/local/bin:/host-bin:ro ...
EXPOSE 3000

# Default entrypoint using deno.json config
ENTRYPOINT ["deno", "run", "--config=deno.json", "--allow-run", "--allow-read", "--allow-write", "--allow-env", "--allow-net", "main.js"]
