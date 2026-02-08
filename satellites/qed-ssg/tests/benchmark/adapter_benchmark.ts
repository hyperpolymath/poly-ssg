// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
// tests/benchmark/adapter_benchmark.ts — Performance benchmarks for SSG adapters

// ============================================================================
// BENCHMARK UTILITIES
// ============================================================================

interface BenchmarkResult {
  name: string;
  iterations: number;
  totalMs: number;
  avgMs: number;
  minMs: number;
  maxMs: number;
  opsPerSec: number;
}

async function benchmark(
  name: string,
  fn: () => Promise<void>,
  iterations: number = 100
): Promise<BenchmarkResult> {
  const times: number[] = [];

  // Warmup
  for (let i = 0; i < 5; i++) {
    await fn();
  }

  // Actual benchmark
  for (let i = 0; i < iterations; i++) {
    const start = performance.now();
    await fn();
    const end = performance.now();
    times.push(end - start);
  }

  const totalMs = times.reduce((a, b) => a + b, 0);
  const avgMs = totalMs / iterations;
  const minMs = Math.min(...times);
  const maxMs = Math.max(...times);
  const opsPerSec = 1000 / avgMs;

  return { name, iterations, totalMs, avgMs, minMs, maxMs, opsPerSec };
}

function formatResult(result: BenchmarkResult): string {
  return `
${result.name}
  Iterations: ${result.iterations}
  Total:      ${result.totalMs.toFixed(2)}ms
  Average:    ${result.avgMs.toFixed(3)}ms
  Min:        ${result.minMs.toFixed(3)}ms
  Max:        ${result.maxMs.toFixed(3)}ms
  Ops/sec:    ${result.opsPerSec.toFixed(2)}
`;
}

// ============================================================================
// ADAPTER LOADING BENCHMARKS
// ============================================================================

Deno.test("Benchmark: Adapter module loading", async () => {
  const results: BenchmarkResult[] = [];

  // Benchmark loading individual adapters
  const adaptersToTest = ["zola", "hakyll", "serum", "cobalt", "franklin"];

  for (const adapter of adaptersToTest) {
    // Clear module cache by using dynamic timestamp
    const result = await benchmark(
      `Load ${adapter} adapter`,
      async () => {
        // Note: In real benchmark, we'd need to clear cache
        await import(`../../adapters/${adapter}.js?t=${Date.now()}`).catch(() => {
          // Fallback to cached version for consistent benchmarking
        });
      },
      50
    );
    results.push(result);
  }

  // Print results
  console.log("\n=== Adapter Loading Benchmarks ===");
  results.forEach(r => console.log(formatResult(r)));
});

Deno.test("Benchmark: Load all 28 adapters", async () => {
  const adapterFiles: string[] = [];
  for await (const entry of Deno.readDir("./adapters")) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      adapterFiles.push(entry.name);
    }
  }

  const result = await benchmark(
    "Load all 28 adapters",
    async () => {
      await Promise.all(
        adapterFiles.map(file => import(`../../adapters/${file}`))
      );
    },
    20
  );

  console.log("\n=== Bulk Loading Benchmark ===");
  console.log(formatResult(result));
});

// ============================================================================
// ADAPTER CONNECTION BENCHMARKS
// ============================================================================

Deno.test("Benchmark: Adapter connect/disconnect cycle", async () => {
  const adapter = await import("../../adapters/zola.js");

  const result = await benchmark(
    "Zola connect/disconnect cycle",
    async () => {
      await adapter.connect();
      await adapter.disconnect();
    },
    50
  );

  console.log("\n=== Connection Cycle Benchmark ===");
  console.log(formatResult(result));
});

// ============================================================================
// TOOL EXECUTION BENCHMARKS
// ============================================================================

Deno.test("Benchmark: Tool lookup", async () => {
  const adapter = await import("../../adapters/zola.js");

  const result = await benchmark(
    "Tool lookup by name",
    async () => {
      adapter.tools.find((t: { name: string }) => t.name === "zola_version");
      adapter.tools.find((t: { name: string }) => t.name === "zola_build");
      adapter.tools.find((t: { name: string }) => t.name === "zola_init");
    },
    1000
  );

  console.log("\n=== Tool Lookup Benchmark ===");
  console.log(formatResult(result));
});

Deno.test("Benchmark: isConnected check", async () => {
  const adapter = await import("../../adapters/zola.js");

  const result = await benchmark(
    "isConnected() call",
    async () => {
      adapter.isConnected();
    },
    10000
  );

  console.log("\n=== Connection Check Benchmark ===");
  console.log(formatResult(result));
});

// ============================================================================
// CONCURRENT OPERATIONS BENCHMARKS
// ============================================================================

Deno.test("Benchmark: Concurrent adapter loading", async () => {
  const adapters = [
    "zola", "cobalt", "mdbook", "hakyll", "ema",
    "serum", "tableau", "franklin", "frog", "pollen"
  ];

  // Sequential loading
  const sequentialResult = await benchmark(
    "Sequential load (10 adapters)",
    async () => {
      for (const adapter of adapters) {
        await import(`../../adapters/${adapter}.js`);
      }
    },
    20
  );

  // Parallel loading
  const parallelResult = await benchmark(
    "Parallel load (10 adapters)",
    async () => {
      await Promise.all(
        adapters.map(adapter => import(`../../adapters/${adapter}.js`))
      );
    },
    20
  );

  console.log("\n=== Concurrency Benchmarks ===");
  console.log(formatResult(sequentialResult));
  console.log(formatResult(parallelResult));
  console.log(`Speedup: ${(sequentialResult.avgMs / parallelResult.avgMs).toFixed(2)}x`);
});

// ============================================================================
// MEMORY BENCHMARKS
// ============================================================================

Deno.test("Benchmark: Memory usage per adapter", async () => {
  // Note: Deno doesn't expose detailed memory stats easily
  // This is a simplified approximation

  const beforeHeap = Deno.memoryUsage().heapUsed;

  const adapters = [];
  for await (const entry of Deno.readDir("./adapters")) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      const adapter = await import(`../../adapters/${entry.name}`);
      adapters.push(adapter);
    }
  }

  const afterHeap = Deno.memoryUsage().heapUsed;
  const totalMemory = afterHeap - beforeHeap;
  const perAdapter = totalMemory / adapters.length;

  console.log("\n=== Memory Usage ===");
  console.log(`Total adapters loaded: ${adapters.length}`);
  console.log(`Total heap increase: ${(totalMemory / 1024).toFixed(2)} KB`);
  console.log(`Per adapter: ${(perAdapter / 1024).toFixed(2)} KB`);
});

// ============================================================================
// SUMMARY REPORT
// ============================================================================

Deno.test("Benchmark: Generate summary report", async () => {
  const results = {
    timestamp: new Date().toISOString(),
    platform: Deno.build.os,
    denoVersion: Deno.version.deno,
    v8Version: Deno.version.v8,
    adapterCount: 28,
    metrics: {} as Record<string, number>,
  };

  // Quick metrics
  const loadStart = performance.now();
  for await (const entry of Deno.readDir("./adapters")) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      await import(`../../adapters/${entry.name}`);
    }
  }
  const loadEnd = performance.now();

  results.metrics.totalLoadTimeMs = loadEnd - loadStart;
  results.metrics.avgLoadTimePerAdapterMs = (loadEnd - loadStart) / 28;

  console.log("\n=== BENCHMARK SUMMARY ===");
  console.log(JSON.stringify(results, null, 2));
});
