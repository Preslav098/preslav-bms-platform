# Device Details — live telemetry, history and plug control

This build adds one shared `DevicePopup` used from Overview, Devices and Floor Plans.

## Included

- Live plug power through `energy.current`, scoped to the selected Shelly ID.
- Live voltage/current from the device status with latest `energy.query` values as fallback.
- Plug relay on/off through the Host SDK `device.call` → `Switch.Set` (`id: 0`).
- BLU H&T temperature, humidity, battery and RSSI.
- BLU Door open/closed state, battery and RSSI.
- 24-hour historical charts for power devices and climate sensors.
- Loading, error and offline states.
- Five-second live refresh only while the popup is open and the Live Measurements tab is active.
- One shared popup for all entry points; the unused duplicate `components/device-details` directory was removed.

## Verified

The template was staged into the supplied Fleet Manager frontend and successfully built with:

```bash
FM_BUILD_MODE=client npm run build:client
```

## Deployment

```bash
cd /var/www/preslav-bms-platform
./deploy-preslav-bms.sh
```
