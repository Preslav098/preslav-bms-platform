# Task 2 final results

## Proven

- 5,000 active simulated Pro 3EM devices
- 5,000 admitted devices
- 5,002 established sockets on port 7011
- 0 waiting and 0 connecting
- 0 handshake failures
- 0 drops
- 0 timeouts
- 0 reconnect storms
- approximately 500 unsolicited messages/s in steady state
- Fleet Manager at approximately 12.56% CPU and 467.4 MiB RAM
- PostgreSQL at approximately 7.39% CPU and 137.4 MiB RAM
- PostgreSQL stable at 17 total connections
- Pro 3EM `em:0` and `emdata:0` components recognized by Fleet Manager
- TimescaleDB hypertable and backend ingestion modules identified

## Not proven

- sustained 5,000-device historical EM writes into `device_em.stats`

The final database observation contained no new EM rows and no WAL movement. The audit report explicitly preserves this limitation.
