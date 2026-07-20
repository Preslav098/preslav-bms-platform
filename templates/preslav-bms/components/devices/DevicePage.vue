<template>
    <section class="device-page">
        <header class="device-page__header">
            <div>
                <p class="device-page__eyebrow">
                    Infrastructure
                </p>

                <h2>Devices</h2>

                <p class="device-page__description">
                    Monitor connected devices, filter their status
                    and inspect current measurements.
                </p>
            </div>
        </header>

        <DeviceStatistics :total="devices.length" :online="onlineCount" :offline="offlineCount"
            :warning="warningCount" />

        <DeviceFilters v-model:search="search" v-model:status="status" />

        <DeviceToolbar v-model:sort="sort" :devices="devices" :visible-count="filteredAndSortedDevices.length"
            :refreshing="refreshing" @refresh="$emit('refresh')" @export="exportDevices"
            @add-device="$emit('add-device')" />

        <DeviceEmptyState v-if="filteredAndSortedDevices.length === 0" :filtered="hasActiveFilters"
            :refreshing="refreshing" @reset="resetFilters" @refresh="$emit('refresh')" />

        <DeviceList :devices="filteredAndSortedDevices" :host-devices="hostDevices"
            @select-device="$emit('select-device', $event)" @remove-device="$emit('remove-device', $event)" />
    </section>
</template>

<script setup lang="ts">
import {
    computed,
    ref
} from 'vue';
import type { HostDevice } from '@host/index';

import DeviceEmptyState from './DeviceEmptyState.vue';
import DeviceFilters from './DeviceFilters.vue';
import DeviceList from './DeviceList.vue';
import DeviceStatistics from './DeviceStatistics.vue';
import DeviceToolbar from './DeviceToolbar.vue';

import type {
    Device,
    DeviceStatusFilter
} from '../../models/Device';
import type { DeviceSort } from './DeviceToolbar.vue';

const props = withDefaults(
    defineProps<{
        devices: Device[];
        refreshing?: boolean;
        hostDevices?: HostDevice[];
    }>(),
    {
        refreshing: false,
        hostDevices: () => []
    }
);

defineEmits<{
    refresh: [];
    'select-device': [device: Device];
    'remove-device': [device: Device];
    'add-device': [];
}>();

const search = ref('');
const status = ref<DeviceStatusFilter>('all');
const sort = ref<DeviceSort>('name-asc');

const onlineCount = computed(() => {
    return props.devices.filter(
        (device) => device.status === 'online'
    ).length;
});

const offlineCount = computed(() => {
    return props.devices.filter(
        (device) => device.status === 'offline'
    ).length;
});

const warningCount = computed(() => {
    return props.devices.filter(
        (device) => device.status === 'warning'
    ).length;
});

const hasActiveFilters = computed(() => {
    return (
        search.value.trim().length > 0 ||
        status.value !== 'all'
    );
});

const filteredAndSortedDevices = computed<Device[]>(() => {
    const query = search.value
        .trim()
        .toLowerCase();

    const filtered = props.devices.filter((device) => {
        const matchesStatus =
            status.value === 'all' ||
            device.status === status.value;

        if (!matchesStatus) {
            return false;
        }

        if (!query) {
            return true;
        }

        const searchableText = [
            device.name,
            device.serial,
            device.model,
            device.location,
            device.status,
            String(device.id)
        ]
            .join(' ')
            .toLowerCase();

        return searchableText.includes(query);
    });

    return [...filtered].sort(compareDevices);
});

function compareDevices(
    first: Device,
    second: Device
): number {
    switch (sort.value) {
        case 'name-desc':
            return second.name.localeCompare(first.name);

        case 'status':
            return first.status.localeCompare(second.status);

        case 'power-desc':
            return second.power - first.power;

        case 'temperature-desc':
            return second.temperature - first.temperature;

        case 'name-asc':
        default:
            return first.name.localeCompare(second.name);
    }
}

function resetFilters(): void {
    search.value = '';
    status.value = 'all';
}

function exportDevices(): void {
    if (props.devices.length === 0) {
        return;
    }

    const headers = [
        'ID',
        'Name',
        'Serial',
        'Model',
        'Location',
        'Status',
        'Power',
        'Voltage',
        'Current',
        'Temperature',
        'Last Seen'
    ];

    const rows = filteredAndSortedDevices.value.map((device) => [
        device.id,
        device.name,
        device.serial,
        device.model,
        device.location,
        device.status,
        device.power,
        device.voltage,
        device.current,
        device.temperature,
        device.lastSeen
    ]);

    const csv = [
        headers,
        ...rows
    ]
        .map((row) =>
            row
                .map(escapeCsvValue)
                .join(',')
        )
        .join('\n');

    const blob = new Blob(
        [csv],
        {
            type: 'text/csv;charset=utf-8'
        }
    );

    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');

    anchor.href = url;
    anchor.download = 'preslav-bms-devices.csv';
    anchor.click();

    URL.revokeObjectURL(url);
}

function escapeCsvValue(
    value: string | number
): string {
    const stringValue = String(value);

    return `"${stringValue.replaceAll('"', '""')}"`;
}
</script>

<style scoped src="./DevicePage.css"></style>