export interface HostEntity {
    id: string | number;
}

export interface HostDevice extends HostEntity {
    name?: string;
    displayName?: string;
    hostname?: string;
    model?: string;
    deviceModel?: string;
    type?: string;
    online: boolean;
    [key: string]: unknown;
}

export interface HostGroup extends HostEntity {
    name?: string;
    displayName?: string;
    title?: string;
    [key: string]: unknown;
}
