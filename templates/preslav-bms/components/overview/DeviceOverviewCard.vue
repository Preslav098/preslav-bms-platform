<template>
    <button
        class="device-overview-card"
        type="button"
        @click="$emit('select', device)"
    >
        <div class="device-overview-card__header">
            <span
                class="device-overview-card__icon"
                :class="iconToneClass"
                aria-hidden="true"
            >
                {{ deviceIcon }}
            </span>

            <span
                class="device-overview-card__status"
                :class="statusClass"
            >
                <span
                    class="device-overview-card__status-dot"
                    aria-hidden="true"
                ></span>

                {{ statusLabel }}
            </span>
        </div>

        <div class="device-overview-card__content">
            <h4>{{ device.name }}</h4>
            <p>{{ device.model }}</p>
        </div>

        <dl class="device-overview-card__readings">
            <div>
                <dt>Location</dt>
                <dd>{{ device.location || 'Unassigned' }}</dd>
            </div>

            <div>
                <dt>{{ primaryLabel }}</dt>
                <dd>{{ primaryValue }}</dd>
            </div>
        </dl>

        <footer class="device-overview-card__footer">
            <span>{{ device.serial }}</span>
            <strong>View device →</strong>
        </footer>
    </button>
</template>

<script setup lang="ts">
import { computed } from 'vue';

import type { Device } from '../../models/Device';

const props = defineProps<{
    device: Device;
}>();

defineEmits<{
    select: [device: Device];
}>();

const normalizedDevice = computed(() => {
    return `${props.device.name} ${props.device.model}`
        .toLowerCase();
});

const isPowerDevice = computed(() => {
    const value = normalizedDevice.value;

    return (
        value.includes('plug') ||
        value.includes('power') ||
        value.includes('3em') ||
        value.includes('pro em') ||
        value.includes('pm')
    );
});

const isDoorDevice = computed(() => {
    const value = normalizedDevice.value;

    return (
        value.includes('door') ||
        value.includes('window')
    );
});

const isClimateDevice = computed(() => {
    const value = normalizedDevice.value;

    return (
        value.includes('h&t') ||
        value.includes('temperature') ||
        value.includes('humidity') ||
        value.includes('climate')
    );
});

const deviceIcon = computed(() => {
    if (isPowerDevice.value) {
        return '⚡';
    }

    if (isDoorDevice.value) {
        return '🚪';
    }

    if (isClimateDevice.value) {
        return '🌡';
    }

    return '◉';
});

const iconToneClass = computed(() => {
    if (isPowerDevice.value) {
        return 'device-overview-card__icon--blue';
    }

    if (isDoorDevice.value) {
        return 'device-overview-card__icon--green';
    }

    if (isClimateDevice.value) {
        return 'device-overview-card__icon--orange';
    }

    return 'device-overview-card__icon--purple';
});

const statusLabel = computed(() => {
    if (props.device.status === 'warning') {
        return 'Warning';
    }

    return props.device.online
        ? 'Online'
        : 'Offline';
});

const statusClass = computed(() => {
    if (props.device.status === 'warning') {
        return 'device-overview-card__status--warning';
    }

    return props.device.online
        ? 'device-overview-card__status--online'
        : 'device-overview-card__status--offline';
});

const primaryLabel = computed(() => {
    if (isPowerDevice.value) {
        return 'Power';
    }

    if (isClimateDevice.value) {
        return 'Temperature';
    }

    if (isDoorDevice.value) {
        return 'Last seen';
    }

    return 'Status';
});

const primaryValue = computed(() => {
    if (isPowerDevice.value) {
        return `${Math.max(props.device.power, 0).toFixed(1)} W`;
    }

    if (
        isClimateDevice.value &&
        Number.isFinite(props.device.temperature) &&
        props.device.temperature !== 0
    ) {
        return `${props.device.temperature.toFixed(1)} °C`;
    }

    if (isDoorDevice.value) {
        return props.device.lastSeen || 'Unknown';
    }

    return statusLabel.value;
});
</script>

<style scoped src="./DeviceOverviewCard.css"></style>
