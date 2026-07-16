<template>
    <Teleport to="body">
        <Transition name="device-popup">
            <div v-if="device" class="device-popup" @click.self="$emit('close')">
                <section class="device-popup__dialog" role="dialog" aria-modal="true"
                    aria-labelledby="device-popup-title">
                    <header class="device-popup__header">
                        <div class="device-popup__identity">
                            <span class="device-popup__icon" :class="deviceIconClass" aria-hidden="true">
                                {{ deviceIcon }}
                            </span>

                            <div>
                                <p class="device-popup__eyebrow">
                                    Device details
                                </p>

                                <h2 id="device-popup-title">
                                    {{ device.name }}
                                </h2>

                                <p>{{ device.model }}</p>
                            </div>
                        </div>

                        <button class="device-popup__close" type="button" aria-label="Close device details"
                            @click="$emit('close')">
                            ×
                        </button>
                    </header>

                    <div class="device-popup__status-row">
                        <DeviceStatusBadge :status="device.status" />

                        <span class="device-popup__connection" :class="{
                            'device-popup__connection--online':
                                device.online,
                            'device-popup__connection--offline':
                                !device.online
                        }">
                            <span aria-hidden="true"></span>

                            {{
                                device.online
                                    ? 'Connected'
                                    : 'Disconnected'
                            }}
                        </span>
                    </div>

                    <nav class="device-popup__tabs" aria-label="Device detail sections">
                        <button type="button" :class="{
                            'device-popup__tab--active':
                                activeTab === 'general'
                        }" @click="activeTab = 'general'">
                            General
                        </button>

                        <button type="button" :class="{
                            'device-popup__tab--active':
                                activeTab === 'measurements'
                        }" @click="activeTab = 'measurements'">
                            Live measurements
                        </button>
                    </nav>

                    <div class="device-popup__body">
                        <section v-if="activeTab === 'general'" class="device-popup__general">
                            <div class="device-popup__section-heading">
                                <div>
                                    <p>Device information</p>
                                    <h3>General details</h3>
                                </div>
                            </div>

                            <dl class="device-popup__details">
                                <div>
                                    <dt>Device ID</dt>
                                    <dd>{{ device.id }}</dd>
                                </div>

                                <div>
                                    <dt>Serial</dt>
                                    <dd>
                                        {{ device.serial || 'Unknown' }}
                                    </dd>
                                </div>

                                <div>
                                    <dt>Model</dt>
                                    <dd>
                                        {{ device.model || 'Unknown' }}
                                    </dd>
                                </div>

                                <div>
                                    <dt>Location</dt>
                                    <dd>
                                        {{
                                            device.location ||
                                            'Unassigned'
                                        }}
                                    </dd>
                                </div>

                                <div>
                                    <dt>Connection</dt>
                                    <dd>
                                        {{
                                            device.online
                                                ? 'Connected'
                                                : 'Disconnected'
                                        }}
                                    </dd>
                                </div>

                                <div>
                                    <dt>Last seen</dt>
                                    <dd>
                                        {{
                                            device.lastSeen ||
                                            'Unknown'
                                        }}
                                    </dd>
                                </div>
                            </dl>
                        </section>

                        <section v-else class="device-popup__measurements">
                            <div class="device-popup__section-heading">
                                <div>
                                    <p>Live telemetry</p>
                                    <h3>Current measurements</h3>
                                </div>

                                <span class="device-popup__live-indicator" :class="{
                                    'device-popup__live-indicator--offline':
                                        !device.online
                                }">
                                    <span aria-hidden="true"></span>

                                    {{
                                        device.online
                                            ? 'Live'
                                            : 'Offline'
                                    }}
                                </span>
                            </div>

                            <div class="device-popup__measurement-grid">
                                <article v-if="isPowerDevice" class="device-popup__measurement
                                        device-popup__measurement--blue">
                                    <span class="device-popup__measurement-icon" aria-hidden="true">
                                        ⚡
                                    </span>

                                    <div>
                                        <span>Power</span>

                                        <strong>
                                            {{
                                                formatMeasurement(
                                                    device.power,
                                                    'W'
                                                )
                                            }}
                                        </strong>
                                    </div>
                                </article>

                                <article v-if="isPowerDevice" class="device-popup__measurement
                                        device-popup__measurement--purple">
                                    <span class="device-popup__measurement-icon" aria-hidden="true">
                                        V
                                    </span>

                                    <div>
                                        <span>Voltage</span>

                                        <strong>
                                            {{
                                                formatMeasurement(
                                                    device.voltage,
                                                    'V'
                                                )
                                            }}
                                        </strong>
                                    </div>
                                </article>

                                <article v-if="isPowerDevice" class="device-popup__measurement
                                        device-popup__measurement--green">
                                    <span class="device-popup__measurement-icon" aria-hidden="true">
                                        A
                                    </span>

                                    <div>
                                        <span>Current</span>

                                        <strong>
                                            {{
                                                formatMeasurement(
                                                    device.current,
                                                    'A'
                                                )
                                            }}
                                        </strong>
                                    </div>
                                </article>

                                <article v-if="isClimateDevice" class="device-popup__measurement
                                        device-popup__measurement--orange">
                                    <span class="device-popup__measurement-icon" aria-hidden="true">
                                        🌡
                                    </span>

                                    <div>
                                        <span>Temperature</span>

                                        <strong>
                                            {{
                                                formatMeasurement(
                                                    device.temperature,
                                                    '°C'
                                                )
                                            }}
                                        </strong>
                                    </div>
                                </article>

                                <article v-if="!hasSupportedMeasurements" class="device-popup__measurement-empty">
                                    <span aria-hidden="true">◉</span>

                                    <div>
                                        <strong>
                                            No live measurements
                                        </strong>

                                        <p>
                                            This device does not expose
                                            measurements in the current
                                            device model.
                                        </p>
                                    </div>
                                </article>
                            </div>
                        </section>
                    </div>

                    <footer class="device-popup__footer">
                        <span>
                            Data provided by Fleet Manager
                        </span>

                        <button type="button" @click="$emit('close')">
                            Close
                        </button>
                    </footer>
                </section>
            </div>
        </Transition>
    </Teleport>
</template>

<script setup lang="ts">
import {
    computed,
    ref,
    watch
} from 'vue';

import DeviceStatusBadge from './DeviceStatusBadge.vue';
import type { HostDevice } from '@host/index';

import type { Device } from '../../models/Device';
import {
    extractBluClimate,
    extractBluDoor,
    isBluDoorDevice,
    isBluHTDevice
} from '../../utils/bthome';

type DevicePopupTab =
    | 'general'
    | 'measurements';

const props = defineProps<{
    device: Device | null;
    hostDevice: HostDevice | null;
}>();

defineEmits<{
    close: [];
}>();

const activeTab =
    ref<DevicePopupTab>('general');

const normalizedDevice = computed(() => {
    if (!props.device) {
        return '';
    }

    return [
        props.device.name,
        props.device.model
    ]
        .join(' ')
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

const isClimateDevice = computed(() => {
    const value = normalizedDevice.value;

    return (
        value.includes('h&t') ||
        value.includes('temperature') ||
        value.includes('humidity') ||
        value.includes('climate')
    );
});

const isDoorDevice = computed(() => {
    const value = normalizedDevice.value;

    return (
        value.includes('door') ||
        value.includes('window')
    );
});

const deviceIcon = computed(() => {
    if (isPowerDevice.value) {
        return '⚡';
    }

    if (isClimateDevice.value) {
        return '🌡';
    }

    if (isDoorDevice.value) {
        return '🚪';
    }

    return '◉';
});

const deviceIconClass = computed(() => {
    if (isPowerDevice.value) {
        return 'device-popup__icon--blue';
    }

    if (isClimateDevice.value) {
        return 'device-popup__icon--orange';
    }

    if (isDoorDevice.value) {
        return 'device-popup__icon--green';
    }

    return 'device-popup__icon--purple';
});

const hasSupportedMeasurements = computed(() => {
    return (
        isPowerDevice.value ||
        isClimateDevice.value
    );
});

watch(
    () => props.device?.id,
    () => {
        activeTab.value = 'general';
    }
);

function formatMeasurement(
    value: number | null | undefined,
    unit: string
): string {
    if (
        value === null ||
        value === undefined ||
        !Number.isFinite(value)
    ) {
        return '—';
    }
    if (value === 0 && !props.device?.online) {
        return '—';
    }

    return `${value.toFixed(1)} ${unit}`;
}
</script>

<style scoped src="./DevicePopup.css"></style>
