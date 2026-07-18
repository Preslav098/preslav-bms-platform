# Preslav BMS

A custom Building Management System template for Shelly Fleet Manager. Fleet Manager remains the backend and source of truth; the template replaces the standard UI and communicates exclusively through the Host SDK (`@host`).

## Implemented scope

- Facility-manager overview with current power, climate, door/window, online-device and alert KPIs.
- Live plug power plus 24-hour, 7-day and 30-day energy ranges.
- Live temperature/humidity and 24-hour climate history.
- Live door/window state and locally captured real open/close events.
- Navigable 3D building with floor selection and day/night environment state.
- Uploadable floor schematics, drag-and-drop device placement, persistent plan/marker positions and state legend.
- Device list and detail popup with live readings.
- Real Shelly Plug ON/OFF control through the Host SDK.
- Building → floor → device navigation, with floors mapped to Fleet Manager groups.

## Real data and data ownership

The final UI contains no generated demo telemetry. Device, group, location, live metric and metric-history data comes from Fleet Manager through the Host SDK. Floor-plan images and marker coordinates are template-owned UI configuration and are persisted in browser storage so they survive reloads.

Door/window events displayed by the current template are real state transitions captured while the BMS client is running and retained locally. A production follow-up would persist/query a server-side 24-hour event stream so history is shared across browsers and includes periods when the UI was closed.

## Repository shape

```text
contracts/
templates/
  preslav-bms/
    components/
    composables/
    models/
    services/
    styles/
    utils/
    index.vue
    manifest.ts
deploy-request.json
TASK2_AUDIT.md
task-2-evidence/
```

## Architecture and design decisions

- **Host boundary:** no raw calls to Fleet Manager `/rpc` or REST endpoints; all backend interaction is through `@host`.
- **Modularity:** building, floor, device, energy, climate and access features are separate Vue components with separate CSS files.
- **Client empathy:** the home view prioritizes exceptions and daily operational KPIs rather than presenting every available chart.
- **Live vs historical data:** live cards use Host SDK live metrics; charts use Host SDK history methods and explicit time ranges.
- **Reusable building model:** Fleet Manager locations represent buildings/rooms and groups represent floors.
- **Floor-plan configuration:** schematic and marker layout are UI metadata rather than device telemetry.

## Deploy request

[`deploy-request.json`](deploy-request.json) is the exact customization manifest used for package validation and BM deployment:

```json
{
  "schemaVersion": 1,
  "clientName": "Preslav Facilities",
  "title": "Preslav Building Management System",
  "subtitle": "Energy, climate and access monitoring",
  "buildingName": "Preslav Smart Office"
}
```

## Validation

```bash
cd /var/www/fleet-management/frontend
npm ci

npm run validate:customization -- \
  /var/www/preslav-bms-platform/deploy-request.json

npm run validate:template-package -- \
  /var/www/preslav-bms-platform \
  preslav-bms \
  /var/www/preslav-bms-platform/deploy-request.json

npm run check:template-boundaries -- \
  /var/www/preslav-bms-platform/templates/preslav-bms
```

The three validation gates passed during development. See [`VALIDATION.md`](VALIDATION.md).

## Final build and deployment

The assignment-required deployment path is Fleet Manager’s BM pipeline, not a standalone dev server:

```bash
cd /var/www/fleet-management

./deploy.sh \
  --mode bm \
  --manifest /var/www/preslav-bms-platform/deploy-request.json \
  --template-source /var/www/preslav-bms-platform
```

Local helper scripts are included for the iterative development workflow, but the command above is the authoritative final deployment command.

## Device onboarding

1. Deploy Fleet Manager and open its administration UI.
2. Add the Shelly Plug and configure its outbound Fleet Manager WebSocket.
3. Approve the device from the Waiting Room.
4. Pair the Shelly BLU H&T and Door/Window sensors through the plug acting as a Bluetooth gateway.
5. Approve/assign devices and organize them under locations and floor groups.
6. Open Preslav BMS and verify live readings before recording the walkthrough.

## Task 2 backend audit

The short audit requested by the assignment is in [`TASK2_AUDIT.md`](TASK2_AUDIT.md). Supporting measurements are under [`task-2-evidence/`](task-2-evidence/README.md), with the EM persistence investigation in [`PIPELINE_INVESTIGATION.md`](PIPELINE_INVESTIGATION.md) and a concise outcome summary in [`FINAL_RESULTS.md`](FINAL_RESULTS.md).

## What I would do next

- Persist floor-plan configuration and door events server-side with an approved FM extension point.
- Add shared alert acknowledgement and audit history.
- Validate accessibility and mobile/tablet workflows with facility operators.
- Add automated component and Host SDK contract tests.
- Complete the sustained 5,000-device EM write-path benchmark described in the audit.


## Device lifecycle management

- Waiting-room onboarding directly inside Preslav BMS
- Approve or reject newly connected Shelly devices
- Remove managed devices with confirmation and reconnect guidance
