import type {
    Device,
    DeviceStatus
} from '../models/Device';

interface HostDeviceLike {
    id?: string | number;
    online?: boolean;
}

export function mapHostDevice(
    hostDevice: HostDeviceLike
): Device {
    if (
        hostDevice.id === undefined ||
        hostDevice.id === null
    ) {
        throw new Error(
            'Cannot map Fleet Manager device without an id'
        );
    }

    const record = hostDevice as Record<string, unknown>;
    const id = hostDevice.id;
    const online = hostDevice.online === true;

    return {
        id,

        name:
            readString(record, [
                'name',
                'displayName',
                'hostname',
                'deviceName'
            ]) ?? `Device ${String(id)}`,

        serial:
            readString(record, [
                'serial',
                'mac',
                'deviceId'
            ]) ?? String(id),

        model:
            readString(record, [
                'model',
                'deviceModel',
                'type',
                'generation'
            ]) ?? 'Unknown model',

        location:
            readString(record, [
                'location',
                'room',
                'groupName'
            ]) ?? 'Unassigned',

        status: resolveDeviceStatus(record, online),
        online,

        power:
            readNumber(record, [
                'power',
                'apower'
            ]) ?? 0,

        voltage:
            readNumber(record, [
                'voltage'
            ]) ?? 0,

        current:
            readNumber(record, [
                'current'
            ]) ?? 0,

        temperature:
            readNumber(record, [
                'temperature',
                'temp'
            ]) ?? 0,

        lastSeen:
            readString(record, [
                'lastSeen',
                'last_seen',
                'updatedAt'
            ]) ?? 'Unknown',

        raw: { ...record }
    };
}

export function mapHostDevices(
    hostDevices: readonly HostDeviceLike[]
): Device[] {
    const mappedDevices: Device[] = [];

    for (const hostDevice of hostDevices) {
        if (
            hostDevice.id === undefined ||
            hostDevice.id === null
        ) {
            console.warn(
                'Skipping Fleet Manager device without an id:',
                hostDevice
            );

            continue;
        }

        mappedDevices.push(
            mapHostDevice(hostDevice)
        );
    }

    return mappedDevices;
}

function resolveDeviceStatus(
    record: Record<string, unknown>,
    online: boolean
): DeviceStatus {
    const explicitStatus = readString(
        record,
        ['status']
    );

    if (explicitStatus === 'warning') {
        return 'warning';
    }

    if (
        explicitStatus === 'online' ||
        explicitStatus === 'offline'
    ) {
        return explicitStatus;
    }

    return online
        ? 'online'
        : 'offline';
}

function readString(
    record: Record<string, unknown>,
    propertyNames: readonly string[]
): string | undefined {
    for (const propertyName of propertyNames) {
        const value = record[propertyName];

        if (
            typeof value === 'string' &&
            value.trim().length > 0
        ) {
            return value.trim();
        }
    }

    return undefined;
}

function readNumber(
    record: Record<string, unknown>,
    propertyNames: readonly string[]
): number | undefined {
    for (const propertyName of propertyNames) {
        const value = record[propertyName];

        if (
            typeof value === 'number' &&
            Number.isFinite(value)
        ) {
            return value;
        }

        if (
            typeof value === 'string' &&
            value.trim().length > 0
        ) {
            const parsedValue = Number(value);

            if (Number.isFinite(parsedValue)) {
                return parsedValue;
            }
        }
    }

    return undefined;
}