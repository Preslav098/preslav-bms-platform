<template>
    <Teleport to="body">
        <Transition name="device-popup">
            <div
                v-if="device"
                class="device-popup"
                @click.self="emit('close')"
            >
                <section
                    class="device-popup__dialog"
                    role="dialog"
                    aria-modal="true"
                    aria-labelledby="device-popup-title"
                >
                    <header class="device-popup__header">
                        <div class="device-popup__identity">
                            <span
                                class="device-popup__icon"
                                :class="deviceIconClass"
                                aria-hidden="true"
                            >
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

                        <button
                            class="device-popup__close"
                            type="button"
                            aria-label="Close device details"
                            @click="emit('close')"
                        >
                            ×
                        </button>
                    </header>

                    <div class="device-popup__status-row">
                        <DeviceStatusBadge :status="resolvedStatus" />

                        <span
                            class="device-popup__connection"
                            :class="{
                                'device-popup__connection--online': resolvedOnline,
                                'device-popup__connection--offline': !resolvedOnline
                            }"
                        >
                            <span aria-hidden="true"></span>
                            {{ resolvedOnline ? 'Connected' : 'Disconnected' }}
                        </span>
                    </div>

                    <nav
                        class="device-popup__tabs"
                        aria-label="Device detail sections"
                    >
                        <button
                            type="button"
                            :class="{
                                'device-popup__tab--active': activeTab === 'general'
                            }"
                            @click="activeTab = 'general'"
                        >
                            General
                        </button>

                        <button
                            type="button"
                            :class="{
                                'device-popup__tab--active': activeTab === 'measurements'
                            }"
                            @click="activeTab = 'measurements'"
                        >
                            Live measurements
                        </button>

                        <button
                            type="button"
                            :class="{
                                'device-popup__tab--active': activeTab === 'history'
                            }"
                            @click="activeTab = 'history'"
                        >
                            24h history
                        </button>
                    </nav>

                    <div class="device-popup__body">
                        <section
                            v-if="activeTab === 'general'"
                            class="device-popup__general"
                        >
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
                                    <dt>Shelly ID</dt>
                                    <dd>{{ shellyId || 'Unknown' }}</dd>
                                </div>

                                <div>
                                    <dt>Serial</dt>
                                    <dd>{{ device.serial || 'Unknown' }}</dd>
                                </div>

                                <div>
                                    <dt>Model</dt>
                                    <dd>{{ device.model || 'Unknown' }}</dd>
                                </div>

                                <div>
                                    <dt>Location</dt>
                                    <dd>{{ device.location || 'Unassigned' }}</dd>
                                </div>

                                <div>
                                    <dt>Device type</dt>
                                    <dd>{{ deviceTypeLabel }}</dd>
                                </div>

                                <div>
                                    <dt>Connection</dt>
                                    <dd>
                                        {{ resolvedOnline ? 'Connected' : 'Disconnected' }}
                                    </dd>
                                </div>

                                <div>
                                    <dt>Last seen</dt>
                                    <dd>{{ resolvedLastSeen }}</dd>
                                </div>
                            </dl>
                        </section>

                        <section
                            v-else-if="activeTab === 'measurements'"
                            class="device-popup__measurements"
                        >
                            <div class="device-popup__section-heading">
                                <div>
                                    <p>Live telemetry</p>
                                    <h3>Current measurements</h3>
                                </div>

                                <span
                                    class="device-popup__live-indicator"
                                    :class="{
                                        'device-popup__live-indicator--offline': !resolvedOnline
                                    }"
                                >
                                    <span aria-hidden="true"></span>
                                    {{ resolvedOnline ? 'Live' : 'Offline' }}
                                </span>
                            </div>

                            <p
                                v-if="loadError"
                                class="device-popup__error"
                            >
                                {{ loadError }}
                            </p>

                            <div class="device-popup__measurement-grid">
                                <template v-if="isPowerDevice">
                                    <article class="device-popup__measurement device-popup__measurement--blue">
                                        <span class="device-popup__measurement-icon" aria-hidden="true">⚡</span>
                                        <div>
                                            <span>Power</span>
                                            <strong>{{ formatMeasurement(livePower, 'W', 1) }}</strong>
                                        </div>
                                    </article>

                                    <article class="device-popup__measurement device-popup__measurement--purple">
                                        <span class="device-popup__measurement-icon" aria-hidden="true">V</span>
                                        <div>
                                            <span>Voltage</span>
                                            <strong>{{ formatMeasurement(liveVoltage, 'V', 1) }}</strong>
                                        </div>
                                    </article>

                                    <article class="device-popup__measurement device-popup__measurement--green">
                                        <span class="device-popup__measurement-icon" aria-hidden="true">A</span>
                                        <div>
                                            <span>Current</span>
                                            <strong>{{ formatMeasurement(liveCurrent, 'A', 2) }}</strong>
                                        </div>
                                    </article>

                                    <article class="device-popup__measurement device-popup__measurement--cyan">
                                        <span class="device-popup__measurement-icon" aria-hidden="true">∑</span>
                                        <div>
                                            <span>Energy total</span>
                                            <strong>{{ formatMeasurement(totalEnergyWh, 'Wh', 1) }}</strong>
                                        </div>
                                    </article>
                                </template>

                                <template v-else-if="isClimateDevice">
                                    <article class="device-popup__measurement device-popup__measurement--orange">
                                        <span class="device-popup__measurement-icon" aria-hidden="true">🌡</span>
                                        <div>
                                            <span>Temperature</span>
                                            <strong>{{ formatMeasurement(liveTemperature, '°C', 1) }}</strong>
                                        </div>
                                    </article>

                                    <article class="device-popup__measurement device-popup__measurement--cyan">
                                        <span class="device-popup__measurement-icon" aria-hidden="true">💧</span>
                                        <div>
                                            <span>Humidity</span>
                                            <strong>{{ formatMeasurement(liveHumidity, '%', 0) }}</strong>
                                        </div>
                                    </article>

                                    <article class="device-popup__measurement device-popup__measurement--purple">
                                        <span class="device-popup__measurement-icon" aria-hidden="true">🔋</span>
                                        <div>
                                            <span>Battery</span>
                                            <strong>{{ formatMeasurement(liveBattery, '%', 0) }}</strong>
                                        </div>
                                    </article>

                                    <article class="device-popup__measurement device-popup__measurement--blue">
                                        <span class="device-popup__measurement-icon" aria-hidden="true">📶</span>
                                        <div>
                                            <span>RSSI</span>
                                            <strong>{{ formatMeasurement(liveRssi, 'dBm', 0) }}</strong>
                                        </div>
                                    </article>
                                </template>

                                <template v-else-if="isDoorDevice">
                                    <article
                                        class="device-popup__measurement"
                                        :class="doorOpen === true
                                            ? 'device-popup__measurement--red'
                                            : 'device-popup__measurement--green'"
                                    >
                                        <span class="device-popup__measurement-icon" aria-hidden="true">🚪</span>
                                        <div>
                                            <span>Door state</span>
                                            <strong>{{ doorStateLabel }}</strong>
                                        </div>
                                    </article>

                                    <article class="device-popup__measurement device-popup__measurement--purple">
                                        <span class="device-popup__measurement-icon" aria-hidden="true">🔋</span>
                                        <div>
                                            <span>Battery</span>
                                            <strong>{{ formatMeasurement(liveBattery, '%', 0) }}</strong>
                                        </div>
                                    </article>

                                    <article class="device-popup__measurement device-popup__measurement--blue">
                                        <span class="device-popup__measurement-icon" aria-hidden="true">📶</span>
                                        <div>
                                            <span>RSSI</span>
                                            <strong>{{ formatMeasurement(liveRssi, 'dBm', 0) }}</strong>
                                        </div>
                                    </article>
                                </template>

                                <article
                                    v-else
                                    class="device-popup__measurement-empty"
                                >
                                    <span aria-hidden="true">◉</span>
                                    <div>
                                        <strong>No supported live measurements</strong>
                                        <p>This device does not expose a supported BMS capability.</p>
                                    </div>
                                </article>
                            </div>

                            <section
                                v-if="canControlRelay"
                                class="device-popup__control"
                            >
                                <div>
                                    <p>Relay control</p>
                                    <h3>Plug output</h3>
                                    <span>
                                        Current state:
                                        <strong>{{ relayOn ? 'ON' : 'OFF' }}</strong>
                                    </span>
                                </div>

                                <button
                                    type="button"
                                    :class="{
                                        'device-popup__control-button--on': relayOn
                                    }"
                                    :disabled="controlPending || !resolvedOnline"
                                    @click="toggleRelay"
                                >
                                    {{ controlPending
                                        ? 'Applying…'
                                        : relayOn
                                            ? 'Turn OFF'
                                            : 'Turn ON' }}
                                </button>
                            </section>

                            <p
                                v-if="controlError"
                                class="device-popup__error"
                            >
                                {{ controlError }}
                            </p>
                        </section>

                        <section
                            v-else
                            class="device-popup__history"
                        >
                            <div class="device-popup__section-heading">
                                <div>
                                    <p>Historical telemetry</p>
                                    <h3>Last 24 hours</h3>
                                </div>

                                <span class="device-popup__history-count">
                                    {{ historyRows.length }} points
                                </span>
                            </div>

                            <p
                                v-if="loadError"
                                class="device-popup__error"
                            >
                                {{ loadError }}
                            </p>

                            <div
                                v-if="historyLoading"
                                class="device-popup__measurement-empty"
                            >
                                <span aria-hidden="true">↻</span>
                                <div>
                                    <strong>Loading history</strong>
                                    <p>Reading the latest 24-hour telemetry.</p>
                                </div>
                            </div>

                            <div
                                v-else-if="historySeries.length > 0"
                                class="device-popup__history-list"
                            >
                                <article
                                    v-for="series in historySeries"
                                    :key="series.tag"
                                    class="device-popup__history-card"
                                >
                                    <header>
                                        <div>
                                            <span>{{ series.label }}</span>
                                            <strong>
                                                {{ formatMeasurement(
                                                    series.latest,
                                                    series.unit,
                                                    series.decimals
                                                ) }}
                                            </strong>
                                        </div>

                                        <small>
                                            Min {{ formatCompact(series.min, series.decimals) }} ·
                                            Max {{ formatCompact(series.max, series.decimals) }}
                                        </small>
                                    </header>

                                    <svg
                                        class="device-popup__sparkline"
                                        viewBox="0 0 300 74"
                                        preserveAspectRatio="none"
                                        role="img"
                                        :aria-label="`${series.label} trend`"
                                    >
                                        <polyline
                                            :points="series.polyline"
                                            fill="none"
                                            stroke="currentColor"
                                            stroke-width="3"
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                        />
                                    </svg>
                                </article>
                            </div>

                            <div
                                v-else
                                class="device-popup__measurement-empty"
                            >
                                <span aria-hidden="true">—</span>
                                <div>
                                    <strong>No 24-hour history available</strong>
                                    <p>
                                        No stored telemetry was returned for this device and metric range.
                                    </p>
                                </div>
                            </div>
                        </section>
                    </div>

                    <footer class="device-popup__footer">
                        <span>Live data provided by Fleet Manager Host SDK</span>

                        <div class="device-popup__footer-actions">
                            <button
                                class="device-popup__refresh"
                                type="button"
                                :disabled="refreshing"
                                @click="refreshAll"
                            >
                                <span
                                    :class="{
                                        'device-popup__refresh-icon--spinning':
                                            refreshing
                                    }"
                                    aria-hidden="true"
                                >
                                    ↻
                                </span>

                                {{ refreshing ? 'Refreshing…' : 'Refresh data' }}
                            </button>

                            <button
                                type="button"
                                @click="emit('close')"
                            >
                                Close
                            </button>
                        </div>
                    </footer>
                </section>
            </div>
        </Transition>
    </Teleport>
</template>

<script setup lang="ts">
import {
    computed,
    onBeforeUnmount,
    ref,
    watch
} from 'vue';

import {
    devices as hostDevicesApi,
    metrics,
    type HostDevice
} from '@host/index';

import DeviceStatusBadge from './DeviceStatusBadge.vue';

import type {
    Device,
    DeviceStatus
} from '../../models/Device';

import {
    extractBluClimate,
    extractBluDoor,
    isBluDoorDevice,
    isBluHTDevice
} from '../../utils/bthome';

type DevicePopupTab =
    | 'general'
    | 'measurements'
    | 'history';

type HistoryTag =
    | 'power'
    | 'voltage'
    | 'current'
    | 'temperature'
    | 'humidity';

interface HistoryRow {
    bucket: string;
    shellyID: string | null;
    tag: HistoryTag;
    value: number;
}

interface HistorySeries {
    tag: HistoryTag;
    label: string;
    unit: string;
    decimals: number;
    latest: number;
    min: number;
    max: number;
    polyline: string;
}

const props = defineProps<{
    device: Device | null;
    hostDevice: HostDevice | null;
}>();

const emit = defineEmits<{
    close: [];
    updated: [];
}>();

const activeTab = ref<DevicePopupTab>('general');
const refreshing = ref(false);
const historyLoading = ref(false);
const controlPending = ref(false);
const loadError = ref<string | null>(null);
const controlError = ref<string | null>(null);
const liveEnergyWatts = ref<number | null>(null);
const historyRows = ref<HistoryRow[]>([]);
const relayOverride = ref<boolean | null>(null);

let refreshTimer: ReturnType<typeof setInterval> | null = null;

const normalizedDevice = computed(() => {
    if (!props.device) {
        return '';
    }

    return [
        props.device.name,
        props.device.model,
        props.hostDevice?.type,
        JSON.stringify(props.hostDevice?.capabilities ?? {}),
        JSON.stringify(props.device.raw ?? {})
    ]
        .join(' ')
        .toLowerCase();
});

const isPowerDevice = computed(() => {
    if (
        props.hostDevice?.capabilities?.energy ||
        props.hostDevice?.capabilities?.relay
    ) {
        return true;
    }

    return [
        'plug',
        'power',
        'switch',
        '3em',
        'pro em',
        'em1',
        'pm'
    ].some((keyword) => normalizedDevice.value.includes(keyword));
});

const isClimateDevice = computed(() => {
    return Boolean(
        props.hostDevice &&
        (
            isBluHTDevice(props.hostDevice) ||
            props.hostDevice.capabilities?.temperature
        )
    );
});

const isDoorDevice = computed(() => {
    return Boolean(
        props.hostDevice &&
        (
            isBluDoorDevice(props.hostDevice) ||
            props.hostDevice.capabilities?.door
        )
    );
});

const climateReading = computed(() => {
    if (!props.hostDevice || !isBluHTDevice(props.hostDevice)) {
        return null;
    }

    return extractBluClimate(props.hostDevice);
});

const doorReading = computed(() => {
    if (!props.hostDevice || !isBluDoorDevice(props.hostDevice)) {
        return null;
    }

    return extractBluDoor(props.hostDevice);
});

const shellyId = computed(() => {
    return props.hostDevice?.shellyID ?? readShellyId(props.device) ?? '';
});

const livePower = computed<number | null>(() => {
    return firstFiniteNumber(
        liveEnergyWatts.value,
        props.hostDevice?.capabilities?.energy?.power_w,
        readNestedMetric(props.hostDevice?.status, ['apower', 'power', 'act_power']),
        props.device?.power
    );
});

const liveVoltage = computed<number | null>(() => {
    return firstFiniteNumber(
        readNestedMetric(props.hostDevice?.status, ['voltage']),
        latestHistoryValue('voltage'),
        props.device?.voltage
    );
});

const liveCurrent = computed<number | null>(() => {
    return firstFiniteNumber(
        readNestedMetric(props.hostDevice?.status, ['current']),
        latestHistoryValue('current'),
        props.device?.current
    );
});

const totalEnergyWh = computed<number | null>(() => {
    return firstFiniteNumber(
        props.hostDevice?.capabilities?.energy?.total_energy_wh,
        readNestedMetric(props.hostDevice?.status, [
            'total_act_energy',
            'total_energy',
            'total'
        ])
    );
});

const liveTemperature = computed<number | null>(() => {
    return firstFiniteNumber(
        climateReading.value?.temperature,
        props.hostDevice?.capabilities?.temperature?.temperature_c,
        readNestedMetric(props.hostDevice?.status, ['tC', 'temperature', 'temp'])
    );
});

const liveHumidity = computed<number | null>(() => {
    return firstFiniteNumber(
        climateReading.value?.humidity,
        props.hostDevice?.capabilities?.temperature?.humidity_pct,
        readNestedMetric(props.hostDevice?.status, ['rh', 'humidity'])
    );
});

const liveBattery = computed<number | null>(() => {
    return firstFiniteNumber(
        climateReading.value?.battery,
        doorReading.value?.battery,
        readNestedMetric(props.hostDevice?.status, [
            'battery',
            'battery_pct',
            'percent'
        ])
    );
});

const liveRssi = computed<number | null>(() => {
    return firstFiniteNumber(
        climateReading.value?.rssi,
        doorReading.value?.rssi,
        readNestedMetric(props.hostDevice?.status, ['rssi'])
    );
});

const doorOpen = computed<boolean | null>(() => {
    if (doorReading.value?.open !== null && doorReading.value?.open !== undefined) {
        return doorReading.value.open;
    }

    return props.hostDevice?.capabilities?.door?.open ?? null;
});

const doorStateLabel = computed(() => {
    if (doorOpen.value === true) {
        return 'Open';
    }

    if (doorOpen.value === false) {
        return 'Closed';
    }

    return 'Unknown';
});

const resolvedOnline = computed(() => {
    return props.hostDevice?.online ?? props.device?.online ?? false;
});

const resolvedStatus = computed<DeviceStatus>(() => {
    if (props.device?.status === 'warning') {
        return 'warning';
    }

    return resolvedOnline.value ? 'online' : 'offline';
});

const resolvedLastSeen = computed(() => {
    return (
        climateReading.value?.lastSeen ??
        doorReading.value?.lastSeen ??
        props.device?.lastSeen ??
        'Unknown'
    );
});

const relayOn = computed(() => {
    return relayOverride.value ?? props.hostDevice?.capabilities?.relay?.state ?? false;
});

const canControlRelay = computed(() => {
    return Boolean(
        isPowerDevice.value &&
        props.hostDevice?.capabilities?.relay &&
        shellyId.value
    );
});

const deviceIcon = computed(() => {
    if (isPowerDevice.value) return '⚡';
    if (isClimateDevice.value) return '🌡';
    if (isDoorDevice.value) return '🚪';
    return '◉';
});

const deviceIconClass = computed(() => {
    if (isPowerDevice.value) return 'device-popup__icon--blue';
    if (isClimateDevice.value) return 'device-popup__icon--orange';
    if (isDoorDevice.value) return 'device-popup__icon--green';
    return 'device-popup__icon--purple';
});

const deviceTypeLabel = computed(() => {
    if (isPowerDevice.value) return 'Power / relay device';
    if (isClimateDevice.value) return 'Climate sensor';
    if (isDoorDevice.value) return 'Door / window sensor';
    return 'General device';
});

const requestedHistoryTags = computed<HistoryTag[]>(() => {
    if (isPowerDevice.value) {
        return ['power', 'voltage', 'current'];
    }

    if (isClimateDevice.value) {
        return ['temperature', 'humidity'];
    }

    return [];
});

const historySeries = computed<HistorySeries[]>(() => {
    const definitions: Record<HistoryTag, {
        label: string;
        unit: string;
        decimals: number;
    }> = {
        power: {label: 'Power', unit: 'W', decimals: 1},
        voltage: {label: 'Voltage', unit: 'V', decimals: 1},
        current: {label: 'Current', unit: 'A', decimals: 2},
        temperature: {label: 'Temperature', unit: '°C', decimals: 1},
        humidity: {label: 'Humidity', unit: '%', decimals: 0}
    };

    return requestedHistoryTags.value.flatMap((tag) => {
        const values = historyRows.value
            .filter((row) => row.tag === tag && Number.isFinite(row.value))
            .sort((first, second) => (
                new Date(first.bucket).getTime() - new Date(second.bucket).getTime()
            ))
            .map((row) => row.value);

        if (values.length === 0) {
            return [];
        }

        const definition = definitions[tag];

        return [{
            tag,
            ...definition,
            latest: values[values.length - 1],
            min: Math.min(...values),
            max: Math.max(...values),
            polyline: createPolyline(values)
        }];
    });
});

watch(
    () => props.device?.id,
    () => {
        activeTab.value = 'general';
        relayOverride.value = null;
        historyRows.value = [];
        loadError.value = null;
        controlError.value = null;
        stopAutoRefresh();

        if (props.device) {
            void refreshAll();
            startAutoRefresh();
        }
    },
    {immediate: true}
);

watch(activeTab, (tab) => {
    if (tab === 'history' && historyRows.value.length === 0) {
        void refreshHistory();
    }
});

onBeforeUnmount(() => {
    stopAutoRefresh();
});

async function refreshAll(): Promise<void> {
    if (refreshing.value || !props.device) {
        return;
    }

    refreshing.value = true;
    loadError.value = null;

    try {
        await Promise.all([
            refreshLive(),
            refreshHistory()
        ]);
    } catch (error) {
        loadError.value = error instanceof Error
            ? error.message
            : String(error);
    } finally {
        refreshing.value = false;
    }
}

async function refreshLive(): Promise<void> {
    if (!shellyId.value || !isPowerDevice.value) {
        liveEnergyWatts.value = null;
        return;
    }

    const response = await metrics.current({
        devices: [shellyId.value],
        detail: 'device'
    });

    const row = response.devices?.find((item) => item.shellyID === shellyId.value);
    liveEnergyWatts.value = firstFiniteNumber(row?.watts, response.watts);
}

async function refreshHistory(): Promise<void> {
    if (
        historyLoading.value ||
        !shellyId.value ||
        requestedHistoryTags.value.length === 0
    ) {
        return;
    }

    historyLoading.value = true;

    try {
        const to = new Date();
        const from = new Date(to.getTime() - 24 * 60 * 60 * 1000);
        const response = await metrics.history({
            from: from.toISOString(),
            to: to.toISOString(),
            tags: requestedHistoryTags.value,
            bucket: '15 minutes',
            devices: [shellyId.value],
            perDevice: true
        });

        historyRows.value = response.items as HistoryRow[];
    } finally {
        historyLoading.value = false;
    }
}

async function toggleRelay(): Promise<void> {
    if (
        controlPending.value ||
        !canControlRelay.value ||
        !shellyId.value
    ) {
        return;
    }

    controlPending.value = true;
    controlError.value = null;
    const nextState = !relayOn.value;

    try {
        await hostDevicesApi.call(
            shellyId.value,
            'Switch.Set',
            {
                id: 0,
                on: nextState
            }
        );

        relayOverride.value = nextState;
        emit('updated');
        await refreshLive();
    } catch (error) {
        controlError.value = error instanceof Error
            ? error.message
            : String(error);
    } finally {
        controlPending.value = false;
    }
}

function startAutoRefresh(): void {
    if (refreshTimer) {
        return;
    }

    refreshTimer = setInterval(() => {
        if (props.device && activeTab.value === 'measurements') {
            void refreshLive().catch((error) => {
                loadError.value = error instanceof Error
                    ? error.message
                    : String(error);
            });
        }
    }, 5000);
}

function stopAutoRefresh(): void {
    if (!refreshTimer) {
        return;
    }

    clearInterval(refreshTimer);
    refreshTimer = null;
}

function latestHistoryValue(tag: HistoryTag): number | null {
    const row = historyRows.value
        .filter((item) => item.tag === tag)
        .sort((first, second) => (
            new Date(second.bucket).getTime() - new Date(first.bucket).getTime()
        ))[0];

    return firstFiniteNumber(row?.value);
}

function readShellyId(device: Device | null): string | null {
    if (!device) {
        return null;
    }

    const raw = device.raw ?? {};
    const candidates = [
        raw.shellyID,
        raw.shellyId,
        raw.shelly_id,
        raw.deviceId,
        raw.externalId,
        device.serial
    ];

    for (const candidate of candidates) {
        if (typeof candidate === 'string' && candidate.trim()) {
            return candidate.trim();
        }
    }

    return null;
}

function readNestedMetric(
    source: unknown,
    keys: readonly string[]
): number | null {
    if (!source || typeof source !== 'object') {
        return null;
    }

    for (const [key, value] of Object.entries(source as Record<string, unknown>)) {
        if (keys.includes(key) && typeof value === 'number' && Number.isFinite(value)) {
            return value;
        }

        const nested = readNestedMetric(value, keys);
        if (nested !== null) {
            return nested;
        }
    }

    return null;
}

function firstFiniteNumber(
    ...values: Array<number | null | undefined>
): number | null {
    for (const value of values) {
        if (typeof value === 'number' && Number.isFinite(value)) {
            return value;
        }
    }

    return null;
}

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

function formatCompact(value: number, decimals: number): string {
    return Number.isFinite(value) ? value.toFixed(decimals) : '—';
}

function createPolyline(values: number[]): string {
    if (values.length === 1) {
        return '0,37 300,37';
    }

    const minimum = Math.min(...values);
    const maximum = Math.max(...values);
    const range = maximum - minimum || 1;

    return values
        .map((value, index) => {
            const x = (index / (values.length - 1)) * 300;
            const y = 68 - ((value - minimum) / range) * 60;
            return `${x.toFixed(1)},${y.toFixed(1)}`;
        })
        .join(' ');
}
</script>

<style scoped src="./DevicePopup.css"></style>
