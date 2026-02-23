---
name: perf-test
description: "Guide Flutter performance profiling, low-end device testing, API load testing, and database query benchmarking. Use when user says 'performance test', 'benchmark', 'profile', 'load test', or 'slow'."
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, Grep
metadata:
  version: 1.0.0
---

# Performance Test — Profiling & Benchmarking

Guide performance testing across Flutter app, server API, and database.

## Arguments

`$ARGUMENTS` can be: `flutter`, `api`, `db`, or `all`.

## Steps — Flutter Profiling (`flutter`)

1. **Run in profile mode:**
   ```bash
   cd apps/mobile && flutter run --profile
   ```

2. **Check for jank indicators:**
   - Open DevTools: copy the Observatory URL from console
   - Check Performance overlay for dropped frames
   - Target: 60fps on scoring page during rapid delivery entry

3. **Key screens to profile:**
   - Scoring page — rapid button taps (delivery entry)
   - Match list — scrolling with 50+ matches
   - Analytics charts — rendering Manhattan/Worm with full match data

4. **Low-end device baseline (2GB RAM):**
   - App cold start: target < 3 seconds
   - Scoring page load: target < 1 second
   - Chart rendering: target < 2 seconds
   - Memory usage: target < 150MB during scoring

5. **Report:** FPS, memory usage, startup time, identified bottlenecks.

## Steps — API Load Testing (`api`)

1. **Install k6 or use curl-based benchmarking:**
   ```bash
   # Simple load test with curl (bash/Git Bash on Windows)
   for i in $(seq 1 100); do
     curl -s -o /dev/null -w "%{http_code} %{time_total}s\n" https://api.yourdomain.com/api/v1/matches
   done

   # PowerShell alternative:
   # 1..100 | ForEach-Object { Invoke-WebRequest -Uri "https://api.yourdomain.com/api/v1/matches" -UseBasicParsing | Select-Object StatusCode, @{N='Time';E={$_.Headers['X-Response-Time']}} }
   ```

2. **Key endpoints to test:**
   - `GET /api/v1/matches` — list matches (pagination)
   - `POST /api/v1/deliveries` — record delivery (write path)
   - `GET /api/v1/matches/:id/scorecard` — full scorecard (complex query)
   - WebSocket connection + message throughput

3. **Targets:**
   - P95 response time: < 200ms for reads, < 500ms for writes
   - Concurrent connections: handle 50 WebSocket clients per match
   - Throughput: 100 requests/second sustained

4. **Report:** P50/P95/P99 latencies, error rate, throughput.

## Steps — Database Benchmarking (`db`)

1. **Identify slow queries:**
   ```bash
   psql cricscores -c "SELECT query, calls, mean_exec_time, total_exec_time FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"
   ```

2. **Check index usage:**
   ```bash
   psql cricscores -c "SELECT relname, seq_scan, idx_scan FROM pg_stat_user_tables ORDER BY seq_scan DESC LIMIT 10;"
   ```

3. **Test with realistic data volumes:**
   - 100 matches, 2000 deliveries, 50 players
   - Scorecard query with full batting/bowling stats
   - Career stats aggregation across all matches

4. **Targets:**
   - Scorecard query: < 50ms
   - Career stats: < 100ms
   - Match list (paginated): < 20ms

5. **Report:** Slow queries, missing indexes, optimization recommendations.
