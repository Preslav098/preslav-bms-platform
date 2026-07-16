<template>
    <transition name="drawer">
        <aside v-if="device" class="device-details">
            <header class="device-details__header">
                <div>
                    <h2>{{ device.name }}</h2>
                    <p>{{ device.model }}</p>
                </div>

                <button @click="$emit('close')">
                    ✕
                </button>
            </header>

            <section class="device-details__section">
                <DeviceTelemetryCard title="Power" :value="`${device.power ?? 0} W`" color="blue" />

                <DeviceTelemetryCard title="Temperature" :value="device.temperature ?? '--'" color="orange" />

                <DeviceTelemetryCard title="Humidity" :value="device.humidity ?? '--'" color="cyan" />

                <DeviceTelemetryCard title="RSSI" :value="device.rssi ?? '--'" color="purple" />
            </section>

            <section class="device-details__info">
                <div>
                    <span>Firmware</span>
                    <strong>{{ device.firmware || 'Unknown' }}</strong>
                </div>

                <div>
                    <span>Location</span>
                    <strong>{{ device.location || 'Unassigned' }}</strong>
                </div>

                <div>
                    <span>Serial</span>
                    <strong>{{ device.serial }}</strong>
                </div>
            </section>
        </aside>
    </transition>
</template>

<script setup lang="ts">
import type { Device } from '../../models/Device';
import DeviceTelemetryCard from './DeviceTelemetryCard.vue';

defineProps<{
    device: Device | null;
}>();

defineEmits<{
    close: [];
}>();
</script>

<style scoped src="./DeviceDetailsDrawer.css"></style>