# Task 2 evidence

## `3000-devices/`

Initial/intermediate measurements before the final tuning.

## `connection-exhaustion/`

Evidence of PostgreSQL client exhaustion and the original database pool configuration.

## `5000-final/`

Final connection benchmark evidence:

- Docker resource snapshot;
- PostgreSQL connection state;
- 5,002 established sockets;
- final simulator steady-state line;
- 60-second database/WAL start and end snapshots.

## `pipeline-investigation/`

Additional investigation of historical EM persistence:

- TimescaleDB table/index structure;
- latest EM timestamp and recent-row result;
- simulator Pro 3EM payload verification;
- backend entity/log verification;
- identified EM capture, queue and drain modules.

See [`../PIPELINE_INVESTIGATION.md`](../PIPELINE_INVESTIGATION.md) for interpretation.
