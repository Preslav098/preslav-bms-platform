# EM telemetry pipeline investigation

## Goal

Determine whether the 5,000-device benchmark generated sustained historical EM writes in `device_em.stats`.

## Verified inputs

The supplied `boiled.data.json` includes:

- model `SPEM-003CEBEU` / application `Pro3EM`;
- `NotifyFullStatus`;
- repeated `NotifyStatus`;
- `em:0`;
- `emdata:0`;
- phase current, voltage and active-power fields;
- cumulative active-energy fields.

Fleet Manager logs showed simulated devices being recognized and entities created for `em:0` and `emdata:0`.

## Database structure

`device_em.stats` is a TimescaleDB hypertable. Relevant indexes include:

- `(device, tag, domain, phase, channel, ts)`;
- `(device)`;
- `(device, tag, ts DESC)`;
- `(ts DESC)`.

Daily chunks were present for 15 and 16 July 2026.

## Backend path

Source inspection identified the following path:

```text
ShellyEmHandler
  → energyCapture.captureEnergyRow()
  → emStatsQueue.enqueue()
  → EM sync/drainer and SQL append function
  → device_em.stats
```

`energyCapture` classifies component fields and queues normalized rows. `emStatsQueue` is an in-memory batch buffer that is later drained to PostgreSQL.

## Observation

During the 5,000-device steady-state window:

```text
latest_em_timestamp       = 2026-07-16 07:34:00+00
rows_last_5_minutes       = 0
devices_last_5_minutes    = 0
```

A separate 60-second snapshot showed no `device_em.stats` count change and no WAL LSN change.

## Interpretation

The test conclusively validates connection and ingress stability. It also confirms that the Pro 3EM components and persistence code path exist. It does not establish that fresh simulated data reached the historical TimescaleDB writer during the observation window.

No unsupported claim is made about the exact cause. A focused small-fleet trace is required to identify whether the missing step is notification cadence, EMData synchronization state, timestamp/cursor behavior, classification, queue flushing or another gating condition.
