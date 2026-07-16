<template>
    <section class="floor-page">
        <header class="floor-page__header">
            <div>
                <p class="floor-page__eyebrow">
                    Building structure
                </p>

                <h2>Floor Plans</h2>

                <p class="floor-page__description">
                    Select a floor, inspect its assigned devices and manage
                    the floor-plan image.
                </p>
            </div>

            <div class="floor-page__summary">
                <span>
                    {{ floors.length }}
                    {{ floors.length === 1 ? 'floor' : 'floors' }}
                </span>

                <span>
                    {{ totalDeviceCount }}
                    {{ totalDeviceCount === 1 ? 'device' : 'devices' }}
                </span>
            </div>
        </header>

        <section v-if="floors.length === 0" class="floor-page__empty">
            <span class="floor-page__empty-icon" aria-hidden="true">
                🗺️
            </span>

            <h3>No floors configured</h3>

            <p>
                Fleet Manager groups will appear here as building floors
                after they are created.
            </p>
        </section>

        <div v-else class="floor-page__layout">
            <aside class="floor-page__sidebar" aria-label="Building floors">
                <button v-for="floor in floors" :key="String(floor.id)" type="button" class="floor-page__floor" :class="{
                    'floor-page__floor--active':
                        selectedFloor?.id === floor.id
                }" @click="selectFloor(floor)">
                    <span class="floor-page__floor-icon" aria-hidden="true">
                        {{ getFloorInitial(floor) }}
                    </span>

                    <span class="floor-page__floor-info">
                        <strong>{{ floor.name }}</strong>

                        <small>
                            {{ floor.deviceCount }}
                            {{
                                floor.deviceCount === 1
                                    ? 'device'
                                    : 'devices'
                            }}
                        </small>
                    </span>

                    <span class="floor-page__floor-arrow" aria-hidden="true">
                        →
                    </span>
                </button>
            </aside>

            <FloorDetails v-if="selectedFloor" :floor="selectedFloor" :plan="selectedPlan"
                @select-device="$emit('select-device', $event)" @update-plan="handlePlanUpdate"
                @remove-plan="handlePlanRemove" />
        </div>
    </section>
</template>

<script setup lang="ts">
import {
    computed,
    ref,
    watch
} from 'vue';

import FloorDetails from './FloorDetails.vue';

import { useFloorPlans } from '../../composables/useFloorPlans';

import type { Device } from '../../models/Device';
import type {
    Floor,
    FloorPlan
} from '../../models/Floor';

const props = defineProps<{
    floors: Floor[];
}>();

defineEmits<{
    'select-device': [device: Device];
}>();

const {
    plans,
    getPlan,
    savePlan,
    removePlan
} = useFloorPlans();

const SELECTED_FLOOR_STORAGE_KEY =
    'preslav-bms-selected-floor';

const selectedFloor = ref<Floor | null>(
    findStoredFloor(props.floors) ??
    props.floors[0] ??
    null
);

const totalDeviceCount = computed(() => {
    return props.floors.reduce(
        (total, floor) => total + floor.deviceCount,
        0
    );
});

const selectedPlan = computed<FloorPlan>(() => {
    // Establish a reactive dependency on the plans collection.
    void plans.value;

    if (!selectedFloor.value) {
        return createEmptyPlan();
    }

    return getPlan(selectedFloor.value.id);
});

watch(
    () => props.floors,
    (floors) => {
        if (floors.length === 0) {
            selectedFloor.value = null;
            return;
        }

        const selectedFloorId =
            selectedFloor.value?.id;

        if (
            selectedFloorId === undefined ||
            selectedFloorId === null
        ) {
            selectedFloor.value = floors[0];
            return;
        }

        const refreshedSelectedFloor =
            floors.find(
                (floor) =>
                    String(floor.id) ===
                    String(selectedFloorId)
            );

        selectedFloor.value =
            refreshedSelectedFloor ??
            floors[0];
    },
    {
        deep: true,
        immediate: true
    }
);


function findStoredFloor(
    floors: Floor[]
): Floor | null {
    try {
        const storedFloorId = window.localStorage.getItem(
            SELECTED_FLOOR_STORAGE_KEY
        );

        if (!storedFloorId) {
            return null;
        }

        return floors.find(
            (floor) =>
                String(floor.id) === storedFloorId
        ) ?? null;
    } catch (error) {
        console.warn(
            'Could not restore the selected floor:',
            error
        );

        return null;
    }
}

function selectFloor(floor: Floor): void {
    selectedFloor.value = floor;

    try {
        window.localStorage.setItem(
            SELECTED_FLOOR_STORAGE_KEY,
            String(floor.id)
        );
    } catch (error) {
        console.warn(
            'Could not persist the selected floor:',
            error
        );
    }
}

function handlePlanUpdate(
    plan: FloorPlan
): void {
    if (!selectedFloor.value) {
        return;
    }

    savePlan(
        selectedFloor.value.id,
        plan
    );
}

function handlePlanRemove(): void {
    if (!selectedFloor.value) {
        return;
    }

    removePlan(
        selectedFloor.value.id
    );
}

function getFloorInitial(
    floor: Floor
): string {
    const normalizedName =
        floor.name.trim();

    if (!normalizedName) {
        return 'F';
    }

    return normalizedName
        .charAt(0)
        .toUpperCase();
}

function createEmptyPlan(): FloorPlan {
    return {
        imageUrl: null,
        fileName: null
    };
}
</script>

<style scoped src="./FloorPage.css"></style>