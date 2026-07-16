<template>
    <section class="building-overview">
        <OverviewHeader :refreshing="isRefreshing" :alert-count="activeAlerts.length" @refresh="handleRefresh" />

        <div class="building-overview__kpi-grid">
            <KPICard label="Current power" :value="formatPower(currentPower)" description="Live building demand"
                icon="⚡" tone="blue" :status="currentPower > 0 ? 'Live' : 'Idle'" />

            <KPICard label="Temperature" :value="formatTemperature(climate.temperature)"
                description="Current indoor temperature" icon="🌡" tone="orange" :status="temperatureStatus" />

            <KPICard label="Humidity" :value="formatHumidity(climate.humidity)" description="Current relative humidity"
                icon="💧" tone="cyan" :status="humidityStatus" />

            <KPICard label="Open doors" :value="String(openDoorCount)" :description="doorDescription" icon="🚪"
                :tone="openDoorCount > 0 ? 'red' : 'green'" :status="openDoorCount > 0 ? 'Attention' : 'Secure'" />

            <KPICard label="Devices online" :value="`${onlineDeviceCount} / ${devices.length}`"
                description="Fleet Manager connectivity" icon="◉" tone="green" :status="`${availability}%`" />

            <KPICard label="Active alerts" :value="String(activeAlerts.length)" :description="activeAlerts.length > 0
                ? 'Issues requiring attention'
                : 'No operational issues'
                " icon="!" :tone="activeAlerts.length > 0 ? 'red' : 'purple'" :status="activeAlerts.length > 0
                    ? 'Review'
                    : 'Clear'
                    " />
        </div>

        <div class="building-overview__main-grid">
            <article class="building-overview__panel">
                <header class="building-overview__panel-header">
                    <div>
                        <p>Operational assets</p>
                        <h2>Device status</h2>
                    </div>

                    <button type="button" @click="$emit('navigate', 'devices')">
                        View all →
                    </button>
                </header>

                <div v-if="devices.length === 0" class="building-overview__empty">
                    <strong>No devices available</strong>

                    <p>
                        Approved Fleet Manager devices will appear here.
                    </p>
                </div>

                <div v-else class="building-overview__device-grid">
                    <DeviceOverviewCard v-for="device in visibleDevices" :key="String(device.id)" :device="device"
                        @select="$emit('select-device', $event)" />
                </div>
            </article>

            <aside class="building-overview__side-column">
                <article class="building-overview__panel">
                    <header class="building-overview__panel-header">
                        <div>
                            <p>Attention required</p>
                            <h2>Active alerts</h2>
                        </div>

                        <span class="building-overview__alert-count">
                            {{ activeAlerts.length }}
                        </span>
                    </header>

                    <div v-if="activeAlerts.length === 0" class="building-overview__healthy">
                        <span>✓</span>

                        <div>
                            <strong>All systems normal</strong>

                            <p>
                                No active device or environmental alerts.
                            </p>
                        </div>
                    </div>

                    <div v-else class="building-overview__alerts">
                        <div v-for="alert in activeAlerts" :key="alert.key" class="building-overview__alert" :class="`building-overview__alert--${alert.level}`
                            ">
                            <span class="building-overview__alert-icon">
                                {{ alert.icon }}
                            </span>

                            <div>
                                <strong>{{ alert.title }}</strong>
                                <p>{{ alert.description }}</p>
                            </div>
                        </div>
                    </div>

                    <button class="building-overview__panel-action" type="button" @click="$emit('navigate', 'events')">
                        Open monitoring page
                    </button>
                </article>

                <article class="building-overview__panel">
                    <header class="building-overview__panel-header">
                        <div>
                            <p>Building structure</p>
                            <h2>Floors</h2>
                        </div>

                        <span class="building-overview__floor-count">
                            {{ floors.length }}
                        </span>
                    </header>

                    <div v-if="floors.length === 0" class="building-overview__empty">
                        <strong>No floors configured</strong>

                        <p>
                            Fleet Manager groups are used as building floors.
                        </p>
                    </div>

                    <div v-else class="building-overview__floors">
                        <button v-for="floor in visibleFloors" :key="String(floor.id)" type="button"
                            @click="$emit('select-floor', floor)">
                            <span class="building-overview__floor-icon">
                                {{ getFloorInitial(floor) }}
                            </span>

                            <span>
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

                            <b>→</b>
                        </button>
                    </div>
                </article>
            </aside>
        </div>
    </section>
</template>

<script setup lang="ts">
import {
    computed,
    ref
} from 'vue';

import {
    useLiveMetric,
    type HostDevice
} from '@host/index';

import OverviewHeader from './OverviewHeader.vue';
import KPICard from './KPICard.vue';
import DeviceOverviewCard from './DeviceOverviewCard.vue';

import type { Device } from '../../models/Device';
import type { Floor } from '../../models/Floor';
import type { PageId } from '../../models/Page';

import {
    extractBluClimate,
    extractBluDoor,
    isBluDoorDevice,
    isBluHTDevice
} from '../../utils/bthome';

interface OverviewAlert {
    key: string;
    title: string;
    description: string;
    icon: string;
    level: 'critical' | 'warning';
}

const props = withDefaults(
    defineProps<{
        devices: Device[];
        hostDevices: HostDevice[];
        floors: Floor[];
        refreshing?: boolean;
    }>(),
    {
        refreshing: false
    }
);

const emit = defineEmits<{
    refresh: [];
    navigate: [page: PageId];
    'select-device': [device: Device];
    'select-floor': [floor: Floor];
}>();

const localRefreshing = ref(false);

const liveEnergy = useLiveMetric({
    detail: 'device',
    intervalMs: 10000
});

const climateDevice = computed(() => {
    return props.hostDevices.find(isBluHTDevice);
});

const doorDevice = computed(() => {
    return props.hostDevices.find(isBluDoorDevice);
});

const climate = computed(() => {
    if (!climateDevice.value) {
        return {
            temperature: null,
            humidity: null,
            battery: null,
            rssi: null,
            lastSeen: null,
            online: false
        };
    }

    return extractBluClimate(climateDevice.value);
});

const door = computed(() => {
    if (!doorDevice.value) {
        return {
            open: null,
            state: 'unknown' as const,
            battery: null,
            rssi: null,
            lastSeen: null,
            online: false
        };
    }

    return extractBluDoor(doorDevice.value);
});

const currentPower = computed(() => {
    return Math.max(
        liveEnergy.watts.value ?? 0,
        0
    );
});

const onlineDeviceCount = computed(() => {
    return props.devices.filter((device) => {
        return device.online;
    }).length;
});

const availability = computed(() => {
    if (props.devices.length === 0) {
        return 0;
    }

    return Math.round(
        (
            onlineDeviceCount.value /
            props.devices.length
        ) * 100
    );
});

const openDoorCount = computed(() => {
    return door.value.open === true
        ? 1
        : 0;
});

const doorDescription = computed(() => {
    if (!doorDevice.value) {
        return 'No door sensor detected';
    }

    if (!door.value.online) {
        return 'Door sensor offline';
    }

    return door.value.open === true
        ? 'Opening requires attention'
        : 'All monitored openings secured';
});

const temperatureStatus = computed(() => {
    const value = climate.value.temperature;

    if (value === null) {
        return 'No data';
    }

    if (value < 18) {
        return 'Low';
    }

    if (value > 27) {
        return 'High';
    }

    return 'Comfort';
});

const humidityStatus = computed(() => {
    const value = climate.value.humidity;

    if (value === null) {
        return 'No data';
    }

    if (value < 30) {
        return 'Low';
    }

    if (value > 65) {
        return 'High';
    }

    return 'Normal';
});

const activeAlerts = computed<OverviewAlert[]>(() => {
    const alerts: OverviewAlert[] = [];

    for (const device of props.devices) {
        if (!device.online) {
            alerts.push({
                key: `offline-${String(device.id)}`,
                title: 'Offline device',
                description:
                    `${device.name} is not connected to Fleet Manager.`,
                icon: '◉',
                level: 'critical'
            });
        }
    }

    if (door.value.open === true) {
        alerts.push({
            key: 'door-open',
            title: 'Door is open',
            description:
                `${doorDevice.value?.name ?? 'Door sensor'} reports an open state.`,
            icon: '🚪',
            level: 'critical'
        });
    }

    if (
        door.value.battery !== null &&
        door.value.battery < 20
    ) {
        alerts.push({
            key: 'door-low-battery',
            title: 'Low door sensor battery',
            description:
                `Battery level is ${door.value.battery.toFixed(0)}%.`,
            icon: '🔋',
            level: 'warning'
        });
    }

    if (
        climate.value.battery !== null &&
        climate.value.battery < 20
    ) {
        alerts.push({
            key: 'climate-low-battery',
            title: 'Low climate sensor battery',
            description:
                `Battery level is ${climate.value.battery.toFixed(0)}%.`,
            icon: '🔋',
            level: 'warning'
        });
    }

    if (
        climate.value.temperature !== null &&
        climate.value.temperature > 27
    ) {
        alerts.push({
            key: 'temperature-high',
            title: 'High temperature',
            description:
                `Current temperature is ${climate.value.temperature.toFixed(1)} °C.`,
            icon: '🌡',
            level: 'warning'
        });
    }

    if (
        climate.value.humidity !== null &&
        (
            climate.value.humidity < 30 ||
            climate.value.humidity > 65
        )
    ) {
        alerts.push({
            key: 'humidity-range',
            title: 'Humidity outside comfort range',
            description:
                `Current humidity is ${climate.value.humidity.toFixed(0)}%.`,
            icon: '💧',
            level: 'warning'
        });
    }

    return alerts.slice(0, 6);
});

const visibleDevices = computed(() => {
    return [...props.devices]
        .sort((first, second) => {
            if (first.online === second.online) {
                return first.name.localeCompare(second.name);
            }

            return first.online
                ? -1
                : 1;
        })
        .slice(0, 6);
});

const visibleFloors = computed(() => {
    return props.floors.slice(0, 5);
});

const isRefreshing = computed(() => {
    return (
        props.refreshing ||
        localRefreshing.value
    );
});

async function handleRefresh(): Promise<void> {
    if (localRefreshing.value || props.refreshing) {
        return;
    }

    localRefreshing.value = true;

    try {
        emit('refresh');

        await liveEnergy.refresh();
    } catch (error) {
        console.error(
            'Failed to refresh building overview:',
            error
        );
    } finally {
        localRefreshing.value = false;
    }
}

function formatPower(value: number): string {
    if (value >= 1000) {
        return `${(value / 1000).toFixed(2)} kW`;
    }

    return `${value.toFixed(0)} W`;
}

function formatTemperature(
    value: number | null
): string {
    return value === null
        ? 'No data'
        : `${value.toFixed(1)} °C`;
}

function formatHumidity(
    value: number | null
): string {
    return value === null
        ? 'No data'
        : `${value.toFixed(0)}%`;
}

function getFloorInitial(floor: Floor): string {
    return floor.name
        .trim()
        .charAt(0)
        .toUpperCase() || 'F';
}
</script>

<style scoped src="./BuildingOverview.css"></style>
