import { ref } from 'vue';

import type { FloorPlan } from '../models/Floor';

interface StoredFloorPlan {
    imageUrl: string;
    fileName: string;
}

const STORAGE_KEY = 'preslav-bms-floor-plans';

export function useFloorPlans() {
    const plans = ref<Record<string, FloorPlan>>(
        readStoredPlans()
    );

    function getPlan(
        floorId: string | number
    ): FloorPlan {
        return plans.value[String(floorId)] ?? {
            imageUrl: null,
            fileName: null
        };
    }

    function savePlan(
        floorId: string | number,
        plan: FloorPlan
    ): void {
        plans.value = {
            ...plans.value,
            [String(floorId)]: plan
        };

        persistPlans();
    }

    function removePlan(
        floorId: string | number
    ): void {
        const nextPlans = { ...plans.value };

        delete nextPlans[String(floorId)];

        plans.value = nextPlans;
        persistPlans();
    }

    function persistPlans(): void {
        localStorage.setItem(
            STORAGE_KEY,
            JSON.stringify(plans.value)
        );
    }

    function readStoredPlans(): Record<string, FloorPlan> {
        try {
            const storedValue =
                localStorage.getItem(STORAGE_KEY);

            if (!storedValue) {
                return {};
            }

            const parsedValue =
                JSON.parse(storedValue) as Record<
                    string,
                    StoredFloorPlan
                >;

            return parsedValue;
        } catch {
            return {};
        }
    }

    return {
        plans,
        getPlan,
        savePlan,
        removePlan
    };
}