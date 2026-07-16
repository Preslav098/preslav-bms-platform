# Task 2 – Backend Audit Report

## Methodology

### Test environment

- Fleet Manager (official Docker image)
- TimescaleDB + PostgreSQL
- Redis
- Traefik
- Stress-test simulator using simulated Shelly Pro 3EM devices
- WebSocket device endpoint
- 10-minute ramp-up to 5,000 concurrent devices
- 10-second telemetry interval

### Measurements collected

The following metrics were collected during the benchmark:

- Number of active/admitted devices
- Waiting Room state
- Docker CPU and memory usage
- PostgreSQL connection usage
- Established WebSocket connections
- Stress-test statistics (drops, timeouts, reconnects, failures)
- Backend logs

---

# Measurements

## Final steady-state

| Metric | Result |
|--------|-------:|
| Active devices | 5000 |
| Admitted devices | 5000 |
| Waiting devices | 0 |
| Connecting devices | 0 |
| Connection failures | 0 |
| Drops | 0 |
| Timeouts | 0 |
| Reconnect storms | 0 |
| Established TCP/WebSocket connections | 5002 |
| PostgreSQL connections | 17 total (1 active, 7 idle) |
| Fleet Manager CPU | ~12.6% |
| Fleet Manager RAM | ~467 MB |
| Database CPU | ~7.4% |
| Database RAM | ~137 MB |

The system remained stable for more than 10 minutes after reaching 5,000 concurrent devices.

---

# Findings

The initial benchmark exposed three main bottlenecks.

### 1. Waiting Room capacity

The default Waiting Room configuration became a bottleneck during mass device onboarding. Devices were evicted once the configured capacity was reached.

### 2. PostgreSQL connection exhaustion

During earlier tests PostgreSQL reached its connection limit, resulting in:

```
FATAL: sorry, too many clients already
```

### 3. Device ingress rate limiting

Large bursts of simultaneous WebSocket handshakes triggered:

```
rate_limit_exceeded
```

preventing additional devices from connecting.

After tuning the backend configuration all three bottlenecks were eliminated.

The final benchmark completed with:

- 5000 active devices
- 5000 admitted devices
- zero waiting devices
- zero connection failures

---

# Prioritized recommendations

| Recommendation | Expected impact | Rollout risk |
|---------------|-----------------|--------------|
| Increase Waiting Room capacity for large deployments | Prevents device eviction during mass onboarding | Low |
| Tune ingress handshake and connection limits | Prevents connection throttling during bursts | Low |
| Tune PostgreSQL connection pool | Prevents database connection exhaustion | Medium |
| Increase ingest worker parallelism | Improves telemetry ingestion throughput | Medium |
| Monitor CPU, RAM and database metrics continuously | Detects capacity limits before service degradation | Low |

---

# 5,000+ Device Extrapolation

The benchmark demonstrates that the tested deployment can successfully sustain **5,000 simultaneous connected devices** without connection failures.

Resource utilization remained moderate throughout the benchmark, suggesting additional headroom.

However, scaling beyond 5,000 devices should be validated with additional benchmarks because the workload characteristics may change significantly.

Recommended future benchmarks include:

- 10,000 concurrent devices
- Higher telemetry frequencies
- Multiple organizations
- Reconnect storms
- Long-duration endurance tests

---

# What I Would Look At Next

The next optimization areas would be:

1. PostgreSQL write throughput under sustained telemetry.
2. TimescaleDB chunk sizing and compression.
3. Redis utilization during reconnect storms.
4. WebSocket latency under higher message rates.
5. Horizontal scaling with multiple Fleet Manager instances.
6. Load balancing and high availability.

---

# Conclusion

The benchmark successfully validated Fleet Manager under a simulated load of **5,000 concurrent Shelly devices**.

After tuning Waiting Room limits, ingress rate limits, PostgreSQL connection usage and ingestion settings, the system maintained:

- 5,000 active devices
- 5,000 admitted devices
- 0 waiting devices
- 0 connection failures
- 0 drops
- stable resource utilization

The collected measurements indicate that the platform is stable for the tested workload and provides a solid baseline for future scalability testing beyond 5,000 devices.