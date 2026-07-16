import { ref } from 'vue';

export interface FloorDevicePosition {
    x: number;
    y: number;
}

type FloorDevicePositions = Record<
    string,
    Record<string, FloorDevicePosition>
>;

const STORAGE_KEY = 'preslav-bms-floor-device-positions';

export function useFloorDevicePositions() {
    const positions = ref<FloorDevicePositions>(
        readStoredPositions()
    );

    function getPosition(
        floorId: string | number,
        deviceId: string | number
    ): FloorDevicePosition | undefined {
        return positions.value[String(floorId)]?.[
            String(deviceId)
        ];
    }

    function savePosition(
        floorId: string | number,
        deviceId: string | number,
        position: FloorDevicePosition
    ): void {
        const floorKey = String(floorId);
        const deviceKey = String(deviceId);

        positions.value = {
            ...positions.value,
            [floorKey]: {
                ...(positions.value[floorKey] ?? {}),
                [deviceKey]: {
                    x: clamp(position.x),
                    y: clamp(position.y)
                }
            }
        };

        persist();
    }

    function removePosition(
        floorId: string | number,
        deviceId: string | number
    ): void {
        const floorKey = String(floorId);
        const deviceKey = String(deviceId);
        const floorPositions = {
            ...(positions.value[floorKey] ?? {})
        };

        delete floorPositions[deviceKey];

        positions.value = {
            ...positions.value,
            [floorKey]: floorPositions
        };

        persist();
    }

    function persist(): void {
        localStorage.setItem(
            STORAGE_KEY,
            JSON.stringify(positions.value)
        );
    }

    function readStoredPositions(): FloorDevicePositions {
        try {
            const stored = localStorage.getItem(STORAGE_KEY);

            if (!stored) {
                return {};
            }

            return JSON.parse(stored) as FloorDevicePositions;
        } catch {
            return {};
        }
    }

    function clamp(value: number): number {
        return Math.min(100, Math.max(0, value));
    }

    return {
        positions,
        getPosition,
        savePosition,
        removePosition
    };
}