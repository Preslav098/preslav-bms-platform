import type { HostDevice } from '@host/index';

type UnknownRecord = Record<string, unknown>;

export interface BluClimateReading {
    temperature: number | null;
    humidity: number | null;
    battery: number | null;
    rssi: number | null;
    lastSeen: string | null;
    online: boolean;
}

function asRecord(value: unknown): UnknownRecord {
    return value !== null && typeof value === 'object'
        ? value as UnknownRecord
        : {};
}

function readNumber(
    source: UnknownRecord,
    componentKey: string
): number | null {
    const component = asRecord(source[componentKey]);
    const value = component.value;

    return typeof value === 'number'
        ? value
        : null;
}

export function isBluHTDevice(device: HostDevice): boolean {
    const type = String(device.type ?? '').toUpperCase();
    const name = String(device.name ?? '').toLowerCase();

    return (
        type === 'SBHT-203C' ||
        name.includes('blu h&t')
    );
}

export function extractBluClimate(
    device: HostDevice
): BluClimateReading {
    const status = asRecord(device.status);
    const bluetoothDevice = asRecord(status.bluetoothdevice);
    const transportHealth = asRecord(
        bluetoothDevice.transportHealth
    );

    const transportStatus = transportHealth.status;
    const rssi = transportHealth.lastRssi;
    const lastSeen = transportHealth.lastSeenAt;

    return {
        // BTHome Object ID 69 — temperature
        temperature: readNumber(
            status,
            'bthomesensor:69'
        ),

        // BTHome Object ID 46 — humidity
        humidity: readNumber(
            status,
            'bthomesensor:46'
        ),

        // BTHome Object ID 1 — battery
        battery: readNumber(
            status,
            'bthomesensor:1'
        ),

        rssi:
            typeof rssi === 'number'
                ? rssi
                : null,

        lastSeen:
            typeof lastSeen === 'string'
                ? lastSeen
                : null,

        online:
            transportStatus === 'online' ||
            device.online === true
    };
}
export interface BluDoorReading {
    open: boolean | null;
    state: 'open' | 'closed' | 'unknown';
    battery: number | null;
    rssi: number | null;
    lastSeen: string | null;
    online: boolean;
}

export function isBluDoorDevice(device: HostDevice): boolean {
    const type = String(device.type ?? '').toUpperCase();
    const name = String(device.name ?? '').toLowerCase();

    return (
        type === 'SBDW-002C' ||
        name.includes('blu door') ||
        name.includes('door/window')
    );
}

export function extractBluDoor(
    device: HostDevice
): BluDoorReading {
    const status = asRecord(device.status);

    const bluetoothDevice = asRecord(
        status.bluetoothdevice
    );

    const transportHealth = asRecord(
        bluetoothDevice.transportHealth
    );

    const doorSensor = asRecord(
        status['bthomesensor:45']
    );

    const batterySensor = asRecord(
        status['bthomesensor:202']
    );

    const rawDoorValue = doorSensor.value;
    const rawDoorState = doorSensor.state;
    const rawBattery = batterySensor.value;
    const rawRssi = transportHealth.lastRssi;
    const rawLastSeen = transportHealth.lastSeenAt;

    const open =
        typeof rawDoorValue === 'boolean'
            ? rawDoorValue
            : typeof rawDoorState === 'string'
                ? rawDoorState.toLowerCase() === 'open'
                : null;

    return {
        open,

        state:
            open === true
                ? 'open'
                : open === false
                    ? 'closed'
                    : 'unknown',

        battery:
            typeof rawBattery === 'number'
                ? rawBattery
                : null,

        rssi:
            typeof rawRssi === 'number'
                ? rawRssi
                : null,

        lastSeen:
            typeof rawLastSeen === 'string'
                ? rawLastSeen
                : null,

        online:
            transportHealth.status === 'online' ||
            device.online === true
    };
}