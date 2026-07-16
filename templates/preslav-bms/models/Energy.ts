export type EnergyPeriod = '24h' | '7d' | '30d';

export interface EnergyPoint {
    label: string;
    value: number;
}

export interface EnergyDeviceSummary {
    id: string | number;
    name: string;
    model: string;
    location: string;
    online: boolean;
    power: number;
    voltage: number;
    current: number;
    share: number;
}
