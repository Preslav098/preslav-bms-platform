# Climate history fix

Climate Monitoring now loads history in this order:

1. Fleet Manager `energy.query` for `temperature` and `humidity` over the last 24 hours.
2. Fleet Manager `device.getstatushistory` using the correct status field names (`tC` and `rh`).
3. A browser-persisted fallback made only from real live H&T readings. Samples are retained for 24 hours and collected at most once every five minutes unless the reading changes.

No synthetic or demo telemetry is generated. The included `test-assets/office-floor-plan-test.png` is only a floor-plan image for testing upload and drag-and-drop.
