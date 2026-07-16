import type { Device } from '../models/Device';
import type { Floor } from '../models/Floor';

interface HostGroupLike {
    id?: string | number;
    name?: string;
    displayName?: string;
    title?: string;
    description?: string;
    [key: string]: unknown;
}

export function mapHostGroupsToFloors(
    groups: readonly HostGroupLike[],
    devices: readonly Device[]
): Floor[] {
    return groups.flatMap((group) => {
        if (
            group.id === undefined ||
            group.id === null
        ) {
            console.warn(
                'Skipping Fleet Manager group without an id:',
                group
            );

            return [];
        }

        const groupId = group.id;
        const record = group as Record<string, unknown>;
        const groupName = readGroupName(record);

        const floorDevices = devices.filter((device) => {
            const raw = device.raw;

            if (!raw) {
                return false;
            }

            return matchesGroup(
                raw,
                groupId,
                groupName
            );
        });

        return [
            {
                id: groupId,
                name: groupName,
                description:
                    readString(record, ['description']) ??
                    'Building floor',
                deviceCount: floorDevices.length,
                devices: floorDevices,
                plan: {
                    imageUrl: null,
                    fileName: null
                },
                raw: { ...record }
            }
        ];
    });
}

function matchesGroup(
    deviceRecord: Record<string, unknown>,
    groupId: string | number,
    groupName: string
): boolean {
    const deviceGroupId =
        readId(deviceRecord, [
            'groupId',
            'group_id',
            'group'
        ]);

    if (
        deviceGroupId !== undefined &&
        String(deviceGroupId) === String(groupId)
    ) {
        return true;
    }

    const deviceGroupName = readString(
        deviceRecord,
        [
            'groupName',
            'group_name',
            'location',
            'room'
        ]
    );

    return (
        deviceGroupName !== undefined &&
        deviceGroupName.toLowerCase() ===
        groupName.toLowerCase()
    );
}

function readGroupName(
    record: Record<string, unknown>
): string {
    return (
        readString(
            record,
            [
                'name',
                'displayName',
                'title'
            ]
        ) ?? 'Unnamed floor'
    );
}

function readString(
    record: Record<string, unknown>,
    keys: readonly string[]
): string | undefined {
    for (const key of keys) {
        const value = record[key];

        if (
            typeof value === 'string' &&
            value.trim().length > 0
        ) {
            return value.trim();
        }
    }

    return undefined;
}

function readId(
    record: Record<string, unknown>,
    keys: readonly string[]
): string | number | undefined {
    for (const key of keys) {
        const value = record[key];

        if (
            typeof value === 'string' ||
            typeof value === 'number'
        ) {
            return value;
        }

        if (
            typeof value === 'object' &&
            value !== null
        ) {
            const nestedRecord =
                value as Record<string, unknown>;

            const nestedId = nestedRecord.id;

            if (
                typeof nestedId === 'string' ||
                typeof nestedId === 'number'
            ) {
                return nestedId;
            }
        }
    }

    return undefined;
}