<template>
    <section class="device-page">
        <header class="device-page__header">
            <div>
                <p class="device-page__eyebrow">Infrastructure</p>
                <h2>Devices</h2>
                <p class="device-page__description">
                    Add, remove and monitor Shelly devices directly from the BMS.
                </p>
            </div>
        </header>

        <div v-if="operationMessage" class="device-page__operation-message" :class="{
            'device-page__operation-message--error': operationMessageType === 'error',
            'device-page__operation-message--success': operationMessageType === 'success'
        }">
            {{ operationMessage }}
        </div>

        <DeviceStatistics
            :total="devices.length"
            :online="onlineCount"
            :offline="offlineCount"
            :warning="warningCount"
        />

        <DeviceFilters v-model:search="search" v-model:status="status" />

        <DeviceToolbar
            v-model:sort="sort"
            :devices="devices"
            :visible-count="filteredAndSortedDevices.length"
            :refreshing="refreshing"
            :pending-count="pendingDevices.length"
            @manage="openDeviceManagement"
            @refresh="$emit('refresh')"
            @export="exportDevices"
        />

        <DeviceEmptyState
            v-if="filteredAndSortedDevices.length === 0"
            :filtered="hasActiveFilters"
            :refreshing="refreshing"
            @reset="resetFilters"
            @refresh="$emit('refresh')"
        />

        <DeviceList
            :devices="filteredAndSortedDevices"
            :host-devices="hostDevices"
            @select-device="$emit('select-device', $event)"
            @remove-device="requestDeviceRemoval"
        />

        <DeviceEnrollmentModal
            :open="managementOpen"
            :pending-devices="pendingDevices"
            :loading="waitingRoomLoading"
            :error="waitingRoomError"
            :busy-entry-id="busyEntryId"
            @close="managementOpen = false"
            @refresh="loadWaitingRoom"
            @approve="approvePendingDevice"
            @reject="rejectPendingDevice"
        />

        <DeviceRemoveModal
            :device="deviceToRemove"
            :removing="removingDevice"
            @close="deviceToRemove = null"
            @confirm="removeSelectedDevice"
        />
    </section>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import {
    devices as hostDeviceApi,
    waitingRoom,
    type HostDevice
} from '@host/index';

import DeviceEmptyState from './DeviceEmptyState.vue';
import DeviceEnrollmentModal, {
    type PendingBmsDevice
} from './DeviceEnrollmentModal.vue';
import DeviceFilters from './DeviceFilters.vue';
import DeviceList from './DeviceList.vue';
import DeviceRemoveModal from './DeviceRemoveModal.vue';
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

const emit = defineEmits<{
    refresh: [];
    'select-device': [device: Device];
}>();

const search = ref('');
const status = ref<DeviceStatusFilter>('all');
const sort = ref<DeviceSort>('name-asc');

const managementOpen = ref(false);
const waitingRoomLoading = ref(false);
const waitingRoomError = ref<string | null>(null);
const pendingDevices = ref<PendingBmsDevice[]>([]);
const busyEntryId = ref<string | null>(null);

const deviceToRemove = ref<Device | null>(null);
const removingDevice = ref(false);
const operationMessage = ref<string | null>(null);
const operationMessageType = ref<'success' | 'error'>('success');

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
    const query = search.value.trim().toLowerCase();

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

onMounted(() => {
    void loadWaitingRoom();
});

function compareDevices(first: Device, second: Device): number {
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

async function openDeviceManagement(): Promise<void> {
    managementOpen.value = true;
    await loadWaitingRoom();
}

async function loadWaitingRoom(): Promise<void> {
    if (waitingRoomLoading.value) {
        return;
    }

    waitingRoomLoading.value = true;
    waitingRoomError.value = null;

    try {
        const result = await waitingRoom.callTyped(
            'waitingroom.list',
            {
                state: 'open',
                limit: 200,
                offset: 0
            }
        );

        pendingDevices.value = result.items.map(mapPendingDevice);
    } catch (error) {
        waitingRoomError.value = formatError(
            error,
            'Unable to load the Fleet Manager waiting room.'
        );
    } finally {
        waitingRoomLoading.value = false;
    }
}

async function approvePendingDevice(device: PendingBmsDevice): Promise<void> {
    if (busyEntryId.value) {
        return;
    }

    busyEntryId.value = device.entryId;
    waitingRoomError.value = null;

    try {
        if (device.entryId.startsWith('deviceIngress:')) {
            await waitingRoom.call(
                'approve',
                {
                    entryId: device.entryId,
                    action: 'create_new_device',
                    ...(device.profileId
                        ? { profileId: device.profileId }
                        : {})
                }
            );
        } else {
            await waitingRoom.callTyped(
                'waitingroom.acceptpendingbyexternalid',
                {
                    externalIds: [device.shellyID]
                }
            );
        }

        showOperationMessage(
            `${device.name} was added to Preslav BMS.`,
            'success'
        );

        await Promise.all([
            loadWaitingRoom(),
            refreshManagedDevices()
        ]);
    } catch (error) {
        waitingRoomError.value = formatError(
            error,
            `Unable to add ${device.name}.`
        );
    } finally {
        busyEntryId.value = null;
    }
}

async function rejectPendingDevice(device: PendingBmsDevice): Promise<void> {
    if (busyEntryId.value) {
        return;
    }

    busyEntryId.value = device.entryId;
    waitingRoomError.value = null;

    try {
        if (device.entryId.startsWith('deviceIngress:')) {
            await waitingRoom.callTyped(
                'waitingroom.reject',
                {
                    entryId: device.entryId,
                    detail: 'Rejected from Preslav BMS device management.'
                }
            );
        } else {
            await waitingRoom.callTyped(
                'waitingroom.rejectpending',
                {
                    shellyIDs: [device.shellyID]
                }
            );
        }

        showOperationMessage(
            `${device.name} was rejected from the waiting room.`,
            'success'
        );
        await loadWaitingRoom();
    } catch (error) {
        waitingRoomError.value = formatError(
            error,
            `Unable to reject ${device.name}.`
        );
    } finally {
        busyEntryId.value = null;
    }
}

function requestDeviceRemoval(device: Device): void {
    deviceToRemove.value = device;
}

async function removeSelectedDevice(): Promise<void> {
    const device = deviceToRemove.value;

    if (!device || removingDevice.value) {
        return;
    }

    const hostDevice = findHostDevice(device);

    if (!hostDevice?.shellyID) {
        showOperationMessage(
            `Unable to identify ${device.name} in Fleet Manager.`,
            'error'
        );
        return;
    }

    removingDevice.value = true;

    try {
        await hostDeviceApi.delete(hostDevice.shellyID);
        deviceToRemove.value = null;
        showOperationMessage(
            `${device.name} was removed from Fleet Manager.`,
            'success'
        );
        await refreshManagedDevices();
        await loadWaitingRoom();
    } catch (error) {
        showOperationMessage(
            formatError(error, `Unable to remove ${device.name}.`),
            'error'
        );
    } finally {
        removingDevice.value = false;
    }
}

async function refreshManagedDevices(): Promise<void> {
    emit('refresh');

    // The parent refresh is event based. A short yield lets the Host SDK store
    // reconcile accepted/deleted devices before the list is rendered again.
    await new Promise<void>((resolve) => {
        window.setTimeout(resolve, 350);
    });
}

function findHostDevice(device: Device): HostDevice | null {
    return props.hostDevices.find((hostDevice) => {
        return (
            String(hostDevice.id) === String(device.id) ||
            hostDevice.shellyID === device.serial
        );
    }) ?? null;
}

function mapPendingDevice(item: Record<string, unknown>): PendingBmsDevice {
    const statusRecord = asRecord(item.status);
    const sys = asRecord(statusRecord.sys);
    const deviceInfo = asRecord(sys.device);
    const wifi = asRecord(statusRecord.wifi);
    const eth = asRecord(statusRecord.eth);

    const shellyID = readString(item, ['shellyID', 'reportedExternalId']) || 'Unknown device';
    const entryId = readString(item, ['entryId']) || shellyID;
    const model = readString(deviceInfo, ['model']) || inferModelFromShellyId(shellyID);
    const name =
        readString(deviceInfo, ['name']) ||
        readString(sys, ['app']) ||
        model ||
        shellyID;

    const touchedAt = readNumber(item, ['touchedAt', 'sortTime', 'addedAt']);
    const profileId = readString(item, ['profileId']);
    const connection = eth.ip
        ? 'Ethernet'
        : wifi.sta_ip
            ? 'Wi-Fi'
            : readString(item, ['observedTransport']) || 'Connected';

    return {
        entryId,
        shellyID,
        ...(profileId ? { profileId } : {}),
        name,
        model: model || 'Shelly device',
        connection,
        ip: readString(eth, ['ip']) || readString(wifi, ['sta_ip']) || 'Not reported',
        lastSeen: formatTimestamp(touchedAt),
        icon: resolvePendingIcon(`${name} ${model}`)
    };
}

function asRecord(value: unknown): Record<string, unknown> {
    return typeof value === 'object' && value !== null
        ? value as Record<string, unknown>
        : {};
}

function readString(
    record: Record<string, unknown>,
    keys: readonly string[]
): string | undefined {
    for (const key of keys) {
        const value = record[key];
        if (typeof value === 'string' && value.trim()) {
            return value.trim();
        }
    }
    return undefined;
}

function readNumber(
    record: Record<string, unknown>,
    keys: readonly string[]
): number | undefined {
    for (const key of keys) {
        const value = record[key];
        if (typeof value === 'number' && Number.isFinite(value)) {
            return value;
        }
        if (typeof value === 'string') {
            const parsed = Number(value);
            if (Number.isFinite(parsed)) {
                return parsed;
            }
        }
    }
    return undefined;
}

function inferModelFromShellyId(shellyID: string): string {
    const prefix = shellyID.split('-')[0]?.replace(/^shelly/i, '').trim();
    return prefix ? `Shelly ${prefix}` : 'Shelly device';
}

function resolvePendingIcon(value: string): string {
    const normalized = value.toLowerCase();
    if (normalized.includes('door') || normalized.includes('window')) return '🚪';
    if (normalized.includes('h&t') || normalized.includes('temperature') || normalized.includes('humidity')) return '🌡';
    if (normalized.includes('plug') || normalized.includes('em') || normalized.includes('pm')) return '⚡';
    return '◉';
}

function formatTimestamp(value: number | undefined): string {
    if (!value) {
        return 'Recently';
    }

    const timestamp = value < 10_000_000_000 ? value * 1000 : value;
    const date = new Date(timestamp);

    if (Number.isNaN(date.getTime())) {
        return 'Recently';
    }

    return new Intl.DateTimeFormat(undefined, {
        dateStyle: 'medium',
        timeStyle: 'short'
    }).format(date);
}

function formatError(error: unknown, fallback: string): string {
    if (error instanceof Error && error.message && error.message !== '[object Object]') {
        return error.message;
    }

    const record = asRecord(error);
    const message = readString(record, ['message', 'error', 'detail', 'reason']);
    return message && message !== '[object Object]' ? message : fallback;
}

function showOperationMessage(
    message: string,
    type: 'success' | 'error'
): void {
    operationMessage.value = message;
    operationMessageType.value = type;

    window.setTimeout(() => {
        if (operationMessage.value === message) {
            operationMessage.value = null;
        }
    }, 5000);
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

    const csv = [headers, ...rows]
        .map((row) => row.map(escapeCsvValue).join(','))
        .join('\n');

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');

    anchor.href = url;
    anchor.download = 'preslav-bms-devices.csv';
    anchor.click();

    URL.revokeObjectURL(url);
}

function escapeCsvValue(value: string | number): string {
    const stringValue = String(value);
    return `"${stringValue.replaceAll('"', '""')}"`;
}
</script>

<style scoped src="./DevicePage.css"></style>
