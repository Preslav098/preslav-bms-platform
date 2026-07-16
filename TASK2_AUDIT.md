# Task 2 – Fleet Manager Backend Audit

## Methodology

The supplied `fleet-manager-stress-test` tool was used with the provided Shelly Pro 3EM template (`boiled.data.json`) against a full Fleet Manager stack consisting of Fleet Manager, PostgreSQL/TimescaleDB, Redis, Traefik and Zitadel.

The load was ramped from 0 to 5,000 simulated devices over 10 minutes. Measurements included:

- active, admitted, waiting and connecting devices;
- handshake failures, drops, timeouts and reconnects;
- established WebSocket/TCP connections;
- Fleet Manager and database CPU/memory;
- PostgreSQL connection state;
- Waiting Room and ingress logs;
- TimescaleDB hypertable/chunk metadata;
- latest EM timestamps, recent-row counts and WAL position;
- relevant backend source paths for the EM ingestion pipeline.

The laptop is not the 4-vCPU reference machine, so absolute capacity figures are not treated as directly transferable. The conclusions focus on reproduced bottlenecks and scaling behavior.

## Measurements

### Before tuning

Three reproducible blockers appeared during ramp-up:

1. **PostgreSQL connection exhaustion** – logs reported `sorry, too many clients already`.
2. **Waiting Room capacity** – the default 2,000-device pending limit caused eviction during mass onboarding.
3. **Ingress handshake throttling** – large connection bursts produced `rate_limit_exceeded`.

At an intermediate point with 5,560 approved and 3,637 reporting devices:

- Fleet Manager: approximately 18.5% CPU and 959 MiB RAM;
- PostgreSQL: approximately 11% CPU and 538 MiB RAM.

The host still had CPU and memory headroom, while configuration and connection limits were already failing.

### Applied benchmark tuning

```env
FM_DB_POOL_MAX=25
FM_DEVICE_INGEST_LANES=64

FM_WAITING_ROOM_MAX=10000
FM_WAITING_ROOM_MAX_PER_ORG=10000
FM_WAITING_ROOM_ACCEPT_CHUNK_SIZE=1000
FM_WAITING_ROOM_ACCEPT_CONCURRENCY=32

FM_DEVICE_INGRESS_HANDSHAKES_PER_IP_PER_MINUTE=10000
FM_DEVICE_INGRESS_HANDSHAKES_PER_ORG_PER_MINUTE=10000
FM_DEVICE_INGRESS_HANDSHAKES_PER_IDENTITY_PER_MINUTE=10000
FM_DEVICE_INGRESS_MAX_CONNECTIONS_PER_IP=6000
FM_DEVICE_INGRESS_MAX_CONNECTIONS_PER_ORG=6000
```

The ingress values above are benchmark settings, not unconditional production defaults.

### Final 5,000-device connection run

| Metric | Result |
|---|---:|
| Active devices | 5,000 |
| Admitted devices | 5,000 |
| Waiting / connecting | 0 / 0 |
| Established sockets on port 7011 | 5,002 |
| Failures | 0 |
| Drops / timeouts / reconnects | 0 / 0 / 0 |
| Steady-state unsolicited messages | ~500/s |
| Fleet Manager CPU / RAM | 12.56% / 467.4 MiB |
| PostgreSQL CPU / RAM | 7.39% / 137.4 MiB |
| PostgreSQL connections | 17 total, 1 active, 7 idle, 0 idle-in-transaction |

The simulator remained stable for more than ten minutes after reaching 5,000 active devices.

## EM persistence investigation

The supplied template contains `NotifyFullStatus`, repeated `NotifyStatus`, `em:0`, `emdata:0`, power/current/voltage fields and Pro 3EM model metadata. Fleet Manager logs confirmed that simulated devices were recognized and that `em:0` and `emdata:0` entities were created.

The persistence path was traced to these backend modules:

```text
NotifyStatus / EMData.GetData
        ↓
ShellyEmHandler
        ↓
energyCapture
        ↓
emStatsQueue
        ↓
EM sync / drainer path
        ↓
device_em.stats
```

`device_em.stats` is a TimescaleDB hypertable with daily chunks and indexes for device, tag and timestamp access.

Observed database state during the final test:

| Check | Result |
|---|---|
| Latest `device_em.stats.ts` | 2026-07-16 07:34:00 UTC |
| Rows in previous 5 minutes | 0 |
| Distinct devices in previous 5 minutes | 0 |
| 60-second `device_em.stats` count delta | 0 |
| 60-second WAL LSN change | none |

Therefore the benchmark **proves 5,000 concurrent admitted Pro 3EM WebSocket sessions and stable ingress**, but it does **not prove sustained 5,000-device historical EM persistence**. The evidence shows that the expected components and code path exist, while no new rows reached `device_em.stats` during the observed window. The exact gating condition still requires a focused write-producing test.

## Findings

### 1. PostgreSQL connection budgeting was the highest-impact production fix

The application connection budget could exhaust PostgreSQL before CPU or RAM became limiting. Reducing `FM_DB_POOL_MAX` to 25 removed the reproduced `too many clients` failure. At 5,000 active sessions the database used only 17 connections.

### 2. Waiting Room and handshake limits were onboarding bottlenecks

The default limits prevented a large burst from reaching steady state. Raising them enabled the benchmark, but these settings primarily affect onboarding and reconnect bursts rather than steady-state database write capacity.

### 3. Node/WebSocket ingress was not the final bottleneck

At 5,000 active sessions Fleet Manager remained below 13% sampled CPU and below 500 MiB RAM. No failures, drops, timeouts or reconnect storms occurred.

### 4. Sustained EM write capacity remains the unresolved capacity question

The assignment correctly identifies the database path as the likely long-term limit. Since no fresh EM rows or WAL growth were observed, index cost, chunk growth, write amplification, checkpoint pressure and retention/compression behavior are not yet proven at 5,000 continuously writing devices.

## Prioritized recommendations

| Priority | Recommendation | What to change | Expected impact | Rollout risk |
|---:|---|---|---|---|
| 1 | Enforce a database connection budget | Start with `FM_DB_POOL_MAX=25`; reserve PostgreSQL headroom for migrations, admin access and supporting services | Prevents client exhaustion and stabilizes mixed ingest/query load | **Medium** – an undersized pool can add queueing; monitor pool wait and query latency |
| 2 | Run a write-producing EM benchmark before further tuning | Confirm that each simulated device produces fresh EM timestamps; then capture WAL bytes/s, chunk growth, rows/s, `pg_stat_statements`, checkpoints and disk latency | Identifies the actual database ceiling instead of optimizing the wrong layer | **Low** – measurement-only |
| 3 | Size Waiting Room for expected onboarding bursts | Raise per-org/global capacity only to the intended operational fleet/burst size | Prevents eviction during bulk onboarding | **Low–Medium** – higher memory use and larger abuse surface |
| 4 | Tune ingress limits from measured reconnect behavior | Keep production limits substantially below benchmark values and raise them only with monitoring and abuse controls | Removes false-positive throttling during legitimate reconnect waves | **Medium** – excessive limits weaken protection |
| 5 | Review TimescaleDB layout after a valid write run | Measure the cost of the four visible indexes, chunk interval, compression and retention; remove or alter only what measurements justify | Can reduce write amplification and storage pressure | **High** – index/chunk/policy changes affect live workloads and queries |

## Rollout order

1. Apply and monitor the connection-pool budget.
2. Validate a small write-producing fleet (for example 100 devices).
3. Scale the same telemetry pattern to 1,000, 3,000 and 5,000.
4. Record rows/s, WAL bytes/s, disk latency, checkpoints, query latency and chunk/index growth at each step.
5. Change TimescaleDB indexes, chunking, compression or retention only after the measurements identify a specific cost.
6. Re-run reconnect and endurance tests after every database change.

## 5,000+ extrapolation

The connection test demonstrates that one Fleet Manager process on this machine can hold at least 5,000 concurrent Pro 3EM-class sessions with substantial CPU and memory headroom.

That result cannot be linearly extrapolated to 5,000 continuously writing meters because the final observation window did not produce new `device_em.stats` rows. For the reference 4-vCPU VM, the credible path to 5,000+ is:

- retain the corrected connection budget;
- validate real EM rows per second at increasing fleet sizes;
- measure WAL and storage latency rather than relying on container CPU alone;
- optimize only the confirmed database hot path;
- use a long-duration run to detect checkpoint, retention, compression and query-interference effects.

## What I would look at next

1. Why fresh simulated `NotifyStatus` / `EMData.GetData` data did not advance `device_em.stats`.
2. `pg_stat_statements` top insert/update/query costs during a valid write run.
3. WAL bytes per EM device per minute and checkpoint frequency.
4. Per-index growth and write amplification on `device_em.stats`.
5. TimescaleDB chunk interval, compression scheduling and retention impact.
6. Disk latency and queue depth during sustained ingest plus dashboard/report queries.
7. A 6–24 hour endurance test and a controlled reconnect storm.
8. Horizontal scaling only after the single-instance database ceiling is measured.

## Conclusion

The audit reproduced and removed three real blockers: PostgreSQL client exhaustion, Waiting Room capacity and ingress throttling. After tuning, Fleet Manager sustained 5,000 admitted simulated Pro 3EM sessions with zero failures and moderate resource usage.

The audit does not overstate the result: sustained historical EM persistence at 5,000 devices remains unproven because the final database observation showed no fresh EM rows or WAL movement. That unresolved write path is the first item for the next benchmark.
