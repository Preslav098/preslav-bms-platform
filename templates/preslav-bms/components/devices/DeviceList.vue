<template>
    <section class="device-list">
        <header class="device-list__header">
            <div>
                <p class="device-list__eyebrow">Infrastructure</p>
                <h2>Devices</h2>
                <p>Monitor all connected devices and inspect their current state.</p>
            </div>

            <div class="device-list__summary">
                <span>{{ devices.length }} total </span>
                <span>{{ onlineCount }} online</span>
            </div>
        </header>

        <div v-if="devices.length === 0" class="device-list__empty">
            No devices are currently available.
        </div>

        <div v-else class="device-list__grid">
            <DeviceCard v-for="device in devices" :key="String(device.id)" :device="device"
                :host-device="findHostDevice(device)" @select="$emit('select-device', device)" />
        </div>
    </section>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import type { HostDevice } from '@host/index';

import DeviceCard from './DeviceCard.vue';
import type { Device } from '../../models/Device';

const props = withDefaults(defineProps<{
    devices: Device[];
    hostDevices?: HostDevice[];
}>(), {
    hostDevices: () => []
});

defineEmits<{
    'select-device': [device: Device];
}>();

const onlineCount = computed(() => {
    return props.devices.filter((device) => device.status === 'online').length;
});

function findHostDevice(device: Device): HostDevice | null {
    return props.hostDevices.find((hostDevice) => {
        return String(hostDevice.id) === String(device.id);
    }) ?? null;
}
</script>

<style scoped src="./DeviceList.css"></style>
