# Interactive Floor Plan

Implemented in `templates/preslav-bms/components/floors/`.

Features:
- floor schematic upload and replacement;
- one persisted plan per Fleet Manager group/floor;
- unplaced-device tray;
- drag and drop from the tray onto the plan;
- editable marker positions with automatic local persistence;
- zoom controls;
- device-state colors and legend;
- clicking a marker opens the shared Device Popup.

Persistence keys:
- `preslav-bms-floor-plans`
- `preslav-bms-floor-device-positions`
