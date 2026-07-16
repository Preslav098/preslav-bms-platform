# Preslav BMS
## Custom Building Management System Template for Shelly Fleet Management

---

## Overview

Preslav BMS is a custom Building Management System (BMS) template developed for the Shelly Fleet Management platform.

The project replaces the default Fleet Management interface with a modern Building Management dashboard focused on monitoring buildings, floors, devices and environmental conditions while using Fleet Management as the backend and source of truth.

The template communicates exclusively through the Fleet Management Host SDK and can be deployed as a standalone Fleet Management template package.

---

# Main Features

## Building Overview

The Overview page provides a complete summary of the building.

It includes:

- Current Power Consumption
- Average Temperature
- Average Humidity
- Devices Online
- Open Doors
- Active Alerts
- Device Overview Cards

---

## Building Management

- Building information
- Floor overview
- Building statistics

---

## 3D Building View

Interactive building visualization.

Features:

- Orbit Camera
- Zoom
- Auto Rotation
- Day / Night mode
- Floor highlighting
- Floor selection

---

## Floor Plans

Interactive floor plans with:

- Upload floor plans
- Replace existing floor plans
- Drag & Drop devices
- Persistent device positions
- Device markers
- Floor navigation

---

## Device Monitoring

Complete device management.

Includes:

- Device list
- Search
- Filters
- Device status
- Device popup
- Live telemetry

Supported devices:

- Shelly Plug
- Shelly BLU H&T
- Shelly BLU Door / Window

---

## Device Details

Each device contains:

### Shelly Plug

- Live Power
- Voltage
- Current
- Connection Status
- Device Information
- ON / OFF control

### Shelly BLU H&T

- Temperature
- Humidity
- Battery
- RSSI
- Device Information

### Shelly BLU Door

- Door State
- Battery
- RSSI
- Device Information

---

## Energy Monitoring

Features:

- Live Power
- Device Consumption
- Daily History
- Weekly History
- Monthly History
- Energy Chart
- Device Power Cards

---

## Climate Monitoring

Features:

- Average Temperature
- Average Humidity
- Device Statistics
- 24 Hour History
- Climate Chart

---

## Door & Window Monitoring

Features:

- Live Door State
- Open Doors
- Closed Doors
- Event History
- Device Status

---

## User Interface

Features:

- Dark Theme
- Responsive Layout
- Fixed Sidebar
- Persistent Navigation
- Profile Dialog
- Unified Device Popup
- Modern KPI Cards

---

# Technologies

- Vue 3
- TypeScript
- Host SDK
- CSS
- Vite
- Shelly Fleet Management

---

# Project Structure

```
contracts/

templates/
└── preslav-bms
    ├── components
    ├── composables
    ├── models
    ├── services
    ├── styles
    ├── utils
    ├── manifest.ts
    └── index.vue
```

---

# Architecture

```
Fleet Management Backend
            │
            │
        Host SDK
            │
            ▼
     Preslav BMS Template
            │
    ├── Building Overview
    ├── Building
    ├── 3D Building
    ├── Floor Plans
    ├── Devices
    ├── Energy
    ├── Climate
    └── Door / Window
```

---

# Host SDK

The template communicates with Fleet Management exclusively through the Host SDK.

No direct REST API calls are used.

No custom backend services are required.

---

# Deployment

Build the custom template image:

```bash
cd /var/www/preslav-bms-platform

./deploy-preslav-bms.sh
```

Official Fleet Management deployment:

```bash
deploy.sh \
  --mode bm \
  --manifest deploy-request.json \
  --template-source /path/to/preslav-bms-platform
```

---

# Validation

The project is designed to satisfy the Fleet Management template requirements:

- Template Package Validation
- Template Boundary Validation
- Client Build Validation
- Host SDK only communication

---

# Supported Devices

- Shelly Plug
- Shelly BLU H&T
- Shelly BLU Door / Window

---

# Future Improvements

Possible future improvements include:

- Multi-building support
- Advanced alert engine
- Historical analytics
- Role-based permissions
- Export reports
- Building automation rules

---

# Author

**Preslav Stefanov**

Full Stack Developer

New Bulgarian University

Faculty of Informatics

---

# License

This project was developed as part of a technical assessment for Shelly Fleet Management.