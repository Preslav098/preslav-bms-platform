<template>
    <article
        class="device-card"
        :class="`device-card--${resolvedStatus}`"
    >
        <header class="device-card__header">
            <div class="device-card__identity">
                <span
                    class="device-card__icon"
                    :class="deviceIconClass"
                    aria-hidden="true"
                >
                    {{ deviceIcon }}
                </span>

                <div class="device-card__title">
                    <h3>{{ device.name }}</h3>
                    <p>{{ device.model }}</p>
                </div>
            </div>

            <DeviceStatusBadge :status="resolvedStatus" />
        </header>

        <dl class="device-card__metadata">
            <div>
                <dt>Serial</dt>
                <dd>{{ device.serial || 'Unknown' }}</dd>
            </div>

            <div>
                <dt>Location</dt>
                <dd>{{ device.location || 'Unassigned' }}</dd>
            </div>

            <div>
                <dt>Last seen</dt>
                <dd>{{ resolvedLastSeen }}</dd>
            </div>
        </dl>

        <section class="device-card__measurements">
            <template v-if="isPowerDevice">
                <article>
                    <span>Power</span>
                    <strong>{{ formatMeasurement(device.power, 'W', 1) }}</strong>
                </article>

                <article>
                    <span>Voltage</span>
                    <strong>{{ formatMeasurement(device.voltage, 'V', 1) }}</strong>
                </article>

                <article>
                    <span>Current</span>
                    <strong>{{ formatMeasurement(device.current, 'A', 2) }}</strong>
                </article>

                <article>
                    <span>Connection</span>
                    <strong>{{ resolvedOnline ? 'Online' : 'Offline' }}</strong>
                </article>
            </template>

            <template v-else-if="isDoorDevice">
                <article>
                    <span>Door state</span>
                    <strong>{{ doorStateLabel }}</strong>
                </article>

                <article>
                    <span>Battery</span>
                    <strong>{{ formatMeasurement(doorReading?.battery, '%', 0) }}</strong>
                </article>

                <article>
                    <span>RSSI</span>
                    <strong>{{ formatMeasurement(doorReading?.rssi, 'dBm', 0) }}</strong>
                </article>

                <article>
                    <span>Connection</span>
                    <strong>{{ resolvedOnline ? 'Online' : 'Offline' }}</strong>
                </article>
            </template>

            <template v-else-if="isClimateDevice">
                <article>
                    <span>Temperature</span>
                    <strong>{{ formatMeasurement(climateReading?.temperature, '°C', 1) }}</strong>
                </article>

                <article>
                    <span>Humidity</span>
                    <strong>{{ formatMeasurement(climateReading?.humidity, '%', 0) }}</strong>
                </article>

                <article>
                    <span>Battery</span>
                    <strong>{{ formatMeasurement(climateReading?.battery, '%', 0) }}</strong>
                </article>

                <article>
                    <span>RSSI</span>
                    <strong>{{ formatMeasurement(climateReading?.rssi, 'dBm', 0) }}</strong>
                </article>
            </template>

            <template v-else>
                <article>
                    <span>Status</span>
                    <strong>{{ resolvedOnline ? 'Online' : 'Offline' }}</strong>
                </article>

                <article>
                    <span>Type</span>
                    <strong>{{ device.model || 'Unknown' }}</strong>
                </article>
            </template>
        </section>

        <footer class="device-card__footer">
            <button
                class="device-card__remove"
                type="button"
                @click="$emit('remove')"
            >
                Remove
            </button>

            <button
                class="device-card__details"
                type="button"
                @click="$emit('select')"
            >
                View details
                <span aria-hidden="true">→</span>
            </button>
        </footer>
    </article>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { HostDevice } from '@host/index';

import DeviceStatusBadge from './DeviceStatusBadge.vue';
import type { Device, DeviceStatus } from '../../models/Device';
import {
    extractBluClimate,
    extractBluDoor,
    isBluDoorDevice,
    isBluHTDevice
} from '../../utils/bthome';

const props = defineProps<{
    device: Device;
    hostDevice?: HostDevice | null;
}>();

defineEmits<{
    select: [];
    remove: [];
}>();

const normalizedDevice = computed(() => {
    return [
        props.device.name,
        props.device.model,
        props.hostDevice?.type
    ]
        .join(' ')
        .toLowerCase();
});

const isDoorDevice = computed(() => {
    return props.hostDevice
        ? isBluDoorDevice(props.hostDevice)
        : normalizedDevice.value.includes('door') ||
          normalizedDevice.value.includes('window');
});

const isClimateDevice = computed(() => {
    return props.hostDevice
        ? isBluHTDevice(props.hostDevice)
        : normalizedDevice.value.includes('h&t') ||
          normalizedDevice.value.includes('temperature') ||
          normalizedDevice.value.includes('humidity');
});

const isPowerDevice = computed(() => {
    if (isDoorDevice.value || isClimateDevice.value) {
        return false;
    }

    return [
        'plug',
        'power',
        'switch',
        '3em',
        ' em',
        'pm'
    ].some((keyword) => normalizedDevice.value.includes(keyword));
});

const climateReading = computed(() => {
    if (!props.hostDevice || !isClimateDevice.value) {
        return null;
    }

    return extractBluClimate(props.hostDevice);
});

const doorReading = computed(() => {
    if (!props.hostDevice || !isDoorDevice.value) {
        return null;
    }

    return extractBluDoor(props.hostDevice);
});

const resolvedOnline = computed(() => {
    return (
        climateReading.value?.online ??
        doorReading.value?.online ??
        props.device.online
    );
});

const resolvedStatus = computed<DeviceStatus>(() => {
    if (props.device.status === 'warning') {
        return 'warning';
    }

    return resolvedOnline.value ? 'online' : 'offline';
});

const resolvedLastSeen = computed(() => {
    return (
        climateReading.value?.lastSeen ??
        doorReading.value?.lastSeen ??
        props.device.lastSeen ??
        'Unknown'
    );
});

const doorStateLabel = computed(() => {
    if (doorReading.value?.open === true) {
        return 'Open';
    }

    if (doorReading.value?.open === false) {
        return 'Closed';
    }

    return 'No data';
});

const deviceIcon = computed(() => {
    if (isPowerDevice.value) return '⚡';
    if (isDoorDevice.value) return '🚪';
    if (isClimateDevice.value) return '🌡';
    return '◉';
});

const deviceIconClass = computed(() => {
    if (isPowerDevice.value) return 'device-card__icon--power';
    if (isDoorDevice.value) return 'device-card__icon--door';
    if (isClimateDevice.value) return 'device-card__icon--climate';
    return 'device-card__icon--default';
});

function formatMeasurement(
    value: number | null | undefined,
    unit: string,
    decimals: number
): string {
    if (typeof value !== 'number' || !Number.isFinite(value)) {
        return 'No data';
    }

    return `${value.toFixed(decimals)} ${unit}`;
}
</script>

<style scoped src="./DeviceCard.css"></style>
