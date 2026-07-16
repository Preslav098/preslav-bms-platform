export type DeviceStatus =
    | 'online'
    | 'offline'
    | 'warning';

export type DeviceStatusFilter =
    | 'all'
    | DeviceStatus;

export interface Device {
    id: string | number;

    name: string;
    serial: string;
    model: string;
    location: string;

    status: DeviceStatus;
    online: boolean;

    power: number;
    voltage: number;
    current: number;
    temperature: number;

    lastSeen: string;

    floorX?: number;
    floorY?: number;

    raw?: Record<string, unknown>;
}