# Proven Library Integration Plan

This document outlines how the [proven](https://github.com/hyperpolymath/proven) library's formally verified modules can be integrated into poly-ssg-mcp.

## Applicable Modules

### High Priority

| Module | Use Case | Formal Guarantee |
|--------|----------|------------------|
| `SafeTree` | File tree navigation | ValidPath proofs for navigation |
| `SafeSchema` | Template validation | Type-safe frontmatter |
| `SafeGraph` | Build dependency graph | Acyclic dependencies |

### Medium Priority

| Module | Use Case | Formal Guarantee |
|--------|----------|------------------|
| `SafeBuffer` | Incremental build cache | Bounded cache size |
| `SafeProvenance` | Content versioning | Hash-chain integrity |
| `SafeString` | Template interpolation | Injection prevention |

## Integration Points

### 1. File Tree Navigation (SafeTree)

```
ssg_list_content → SafeTree.navigate → typed content entries
ssg_build → SafeTree.preOrder → deterministic build order
```

The zipper pattern enables efficient cursor-based navigation through large content directories.

### 2. Template Schema Validation (SafeSchema)

```
content/post.md → SafeSchema.validate → typed Post
layouts/base.html → SafeSchema.validateTemplate → typed Template
```

Frontmatter is validated against declared schemas:
```yaml
---
title: string (required)
date: datetime (required)
tags: list[string] (optional)
---
```

### 3. Build Graph (SafeGraph)

```
SafeGraph.acyclic templates dependencies → build order
SafeGraph.topologicalSort → parallel-safe build phases
```

Proves no circular dependencies exist in template inheritance.

## SSG-Specific Integrations

| SSG | Primary Module | Use Case |
|-----|----------------|----------|
| Hakyll (Haskell) | SafeGraph | Dependency tracking |
| Zola (Rust) | SafeTree | Content tree |
| Frog (Racket) | SafeSchema | Post validation |
| Cryogen (Clojure) | SafeBuffer | Incremental builds |

## Implementation Notes

For functional SSGs (Hakyll, Frog), proven modules can be directly imported as Idris types transfer cleanly to ML-family languages.

## Status

- [ ] Add SafeTree bindings for content navigation
- [ ] Implement SafeSchema for frontmatter validation
- [ ] Integrate SafeGraph for template dependencies
- [ ] Add incremental build support via SafeBuffer
