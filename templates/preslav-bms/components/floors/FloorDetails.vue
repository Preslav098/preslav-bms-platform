<template>
    <section class="floor-details">
        <header class="floor-details__header">
            <div>
                <p>Selected floor</p>
                <h3>{{ floor.name }}</h3>
                <span>{{ floor.description }}</span>
            </div>

            <div class="floor-details__header-actions">
                <strong>
                    {{ floor.deviceCount }}
                    {{ floor.deviceCount === 1 ? 'device' : 'devices' }}
                </strong>

                <FloorPlanUploader :image-url="plan.imageUrl" @upload="$emit('update-plan', $event)"
                    @remove="$emit('remove-plan')" />
            </div>
        </header>

        <div class="floor-details__plan">
            <FloorCanvas
                :floor-id="floor.id"
                :image-url="plan.imageUrl"
                :alt-text="`${floor.name} floor plan`"
                :devices="floor.devices"
                @select-device="$emit('select-device', $event)"
            />
        </div>

        <section class="floor-details__devices">
            <header>
                <h4>Devices on this floor</h4>
            </header>

            <div v-if="floor.devices.length === 0" class="floor-details__empty">
                No devices are currently assigned to this floor.
            </div>

            <div v-else class="floor-details__device-grid">
                <button v-for="device in floor.devices" :key="String(device.id)" type="button"
                    @click="$emit('select-device', device)">
                    <span :class="{
                        'floor-details__status--online':
                            device.online
                    }"></span>

                    <span>
                        <strong>{{ device.name }}</strong>
                        <small>{{ device.model }}</small>
                    </span>

                    <span>→</span>
                </button>
            </div>
        </section>
    </section>
</template>

<script setup lang="ts">
import FloorPlanUploader from './FloorPlanUploader.vue';

import type { Device } from '../../models/Device';
import type {
    Floor,
    FloorPlan
} from '../../models/Floor';
import FloorCanvas from './FloorCanvas.vue';

defineProps<{
    floor: Floor;
    plan: FloorPlan;
}>();

defineEmits<{
    'select-device': [device: Device];
    'update-plan': [plan: FloorPlan];
    'remove-plan': [];
}>();
</script>

<style scoped src="./FloorDetails.css"></style>