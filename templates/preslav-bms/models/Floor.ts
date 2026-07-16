import type { Device } from './Device';

export interface FloorPlan {
    imageUrl: string | null;
    fileName: string | null;
}

export interface Floor {
    id: string | number;
    name: string;
    description: string;
    deviceCount: number;
    devices: Device[];
    plan: FloorPlan;
    raw?: Record<string, unknown>;
}