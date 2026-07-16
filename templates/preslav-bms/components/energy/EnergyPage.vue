<template>
    <section class="energy-page">
        <header class="energy-page__header">
            <div>
                <p class="energy-page__eyebrow">
                    Electrical performance
                </p>

                <h2>Energy Monitoring</h2>

                <p class="energy-page__description">
                    Live power and historical consumption from Fleet Manager.
                </p>
            </div>

            <button class="energy-page__refresh" type="button" :disabled="isRefreshing" @click="handleRefresh">
                <span :class="{
                    'energy-page__refresh-icon--spinning': isRefreshing
                }">
                    ↻
                </span>

                {{ isRefreshing ? 'Refreshing…' : 'Refresh data' }}
            </button>
        </header>

        <EnergySummary :current-power="currentPower" :average-voltage="averageVoltage" :total-current="totalCurrent"
            :active-devices="activeDeviceCount" :online-meters="onlineMeterCount" :total-meters="powerDevices.length"
            :availability="availability" />

        <div class="energy-page__content-grid">
            <div class="energy-page__chart-column">
                <div
                    v-if="historyLoading && chartPoints.length === 0"
                    class="energy-page__history-state"
                >
                    <span class="energy-page__history-state-icon">↻</span>

                    <div>
                        <strong>Loading energy history</strong>
                        <p>Reading the latest Fleet Manager measurements.</p>
                    </div>
                </div>

                <EnergyChart
                    v-else-if="chartPoints.length > 0"
                    v-model:period="period"
                    :points="chartPoints"
                />

                <div v-else class="energy-page__history-state">
                    <span class="energy-page__history-state-icon">⚡</span>

                    <div class="energy-page__history-state-content">
                        <strong>Waiting for energy readings</strong>
                        <p>
                            The chart will start filling with real plug readings
                            as soon as Fleet Manager publishes them.
                        </p>

                        <div class="energy-page__history-stat-grid">
                            <div>
                                <span>Current load</span>
                                <strong>{{ formatPower(currentPower) }}</strong>
                            </div>

                            <div>
                                <span>Online meters</span>
                                <strong>{{ onlineMeterCount }}/{{ powerDevices.length }}</strong>
                            </div>

                            <div>
                                <span>Availability</span>
                                <strong>{{ availability }}%</strong>
                            </div>
                        </div>

                        <small v-if="historyNotice">
                            {{ historyNotice }}
                        </small>
                    </div>
                </div>

                <div class="energy-page__period-selector">
                    <button v-for="option in periodOptions" :key="option.value" type="button" :class="{
                        'energy-page__period-selector-button--active':
                            period === option.value
                    }" @click="period = option.value">
                        {{ option.label }}
                    </button>
                </div>
            </div>

            <article class="energy-page__insights">
                <header>
                    <div>
                        <p>Live insights</p>
                        <h3>Building load</h3>
                    </div>

                    <span>
                        {{ powerDevices.length }}
                        {{ powerDevices.length === 1 ? 'meter' : 'meters' }}
                    </span>
                </header>

                <div class="energy-page__gauge">
                    <div class="energy-page__gauge-value">
                        <strong>{{ formatPower(currentPower) }}</strong>
                        <span>current demand</span>
                    </div>
                </div>

                <div class="energy-page__insight-list">
                    <div>
                        <span>Consumption — {{ periodLabel }}</span>
                        <strong>
                            {{ formatEnergy(selectedConsumption) }}
                        </strong>
                    </div>

                    <div>
                        <span>Consumption — last 24H</span>
                        <strong>
                            {{ formatEnergy(consumption24Hours) }}
                        </strong>
                    </div>

                    <div>
                        <span>Highest consumer</span>
                        <strong>
                            {{ highestConsumer?.name ?? 'No data' }}
                        </strong>
                    </div>

                    <div>
                        <span>Peak device load</span>
                        <strong>
                            {{ formatPower(highestConsumer?.power ?? 0) }}
                        </strong>
                    </div>

                    <div>
                        <span>Voltage</span>
                        <strong>
                            {{ formatVoltage(averageVoltage) }}
                        </strong>
                    </div>

                    <div>
                        <span>Current</span>
                        <strong>
                            {{ formatCurrent(totalCurrent) }}
                        </strong>
                    </div>

                    <div>
                        <span>Meter availability</span>
                        <strong>{{ availability }}%</strong>
                    </div>
                </div>
            </article>
        </div>

        <section class="energy-page__devices">
            <header class="energy-page__section-header">
                <div>
                    <p>Connected loads</p>
                    <h3>Power devices</h3>
                </div>

                <span>{{ powerDevices.length }} detected</span>
            </header>

            <div v-if="powerDevices.length === 0" class="energy-page__empty">
                <span>ϟ</span>

                <h3>No energy meters found</h3>

                <p>
                    Connect a power-capable Shelly device and wait for Fleet
                    Manager to publish its readings.
                </p>
            </div>

            <div v-else class="energy-page__device-grid">
                <PowerDeviceCard v-for="device in powerDevices" :key="String(device.id)" :device="device" />
            </div>
        </section>
    </section>
</template>

<script setup lang="ts">
import {
    computed,
    onBeforeUnmount,
    onMounted,
    ref,
    watch
} from 'vue';

import {
    useLiveMetric,
    useMetricHistory
} from '@host/index';

import EnergyChart from './EnergyChart.vue';
import EnergySummary from './EnergySummary.vue';
import PowerDeviceCard from './PowerDeviceCard.vue';

import type { Device } from '../../models/Device';

import type {
    EnergyDeviceSummary,
    EnergyPeriod,
    EnergyPoint
} from '../../models/Energy';

const props = withDefaults(
    defineProps<{
        devices: Device[];
        refreshing?: boolean;
    }>(),
    {
        refreshing: false
    }
);

const emit = defineEmits<{
    refresh: [];
}>();

const DAY_MS = 24 * 60 * 60 * 1000;

const period = ref<EnergyPeriod>('24h');
const locallyRefreshing = ref(false);

interface LocalEnergySample {
    timestamp: string;
    value: number;
}

const LOCAL_HISTORY_KEY = 'preslav-bms-energy-live-history';
const MIN_SAMPLE_INTERVAL_MS = 30_000;
const localEnergySamples = ref<LocalEnergySample[]>(readLocalEnergySamples());
let localSampleTimer: ReturnType<typeof setInterval> | null = null;

const periodOptions: Array<{
    label: string;
    value: EnergyPeriod;
}> = [
        { label: '24H', value: '24h' },
        { label: '7D', value: '7d' },
        { label: '30D', value: '30d' }
    ];

const liveEnergy = useLiveMetric({
    detail: 'device',
    intervalMs: 3000
});

const queryCreationTime = new Date();

/*
 * Във всяка заявка вземаме:
 * - power — историческа средна мощност във W;
 * - total_act_energy — реална консумация в kWh;
 * - voltage — напрежение;
 * - current — ток.
 */
const history24Hours = useMetricHistory({
    from: new Date(
        queryCreationTime.getTime() - DAY_MS
    ).toISOString(),
    to: queryCreationTime.toISOString(),
    tags: [
        'power',
        'total_act_energy',
        'voltage',
        'current'
    ],
    bucket: '1 hour',
    perDevice: true
});

const history7Days = useMetricHistory({
    from: new Date(
        queryCreationTime.getTime() - 7 * DAY_MS
    ).toISOString(),
    to: queryCreationTime.toISOString(),
    tags: [
        'power',
        'total_act_energy',
        'voltage',
        'current'
    ],
    bucket: '1 hour',
    perDevice: true
});

const history30Days = useMetricHistory({
    from: new Date(
        queryCreationTime.getTime() - 30 * DAY_MS
    ).toISOString(),
    to: queryCreationTime.toISOString(),
    tags: [
        'power',
        'total_act_energy',
        'voltage',
        'current'
    ],
    bucket: '6 hours',
    perDevice: true
});

const currentHistory = computed(() => {
    if (period.value === '7d') {
        return history7Days;
    }

    if (period.value === '30d') {
        return history30Days;
    }

    return history24Hours;
});

const periodLabel = computed(() => {
    if (period.value === '7d') {
        return '7 days';
    }

    if (period.value === '30d') {
        return '30 days';
    }

    return '24 hours';
});

const historyLoading = computed(() => {
    return currentHistory.value.loading.value;
});

const historyNotice = computed<string | null>(() => {
    const rawError = currentHistory.value.error.value;

    if (
        rawError === null ||
        rawError === undefined ||
        rawError === false
    ) {
        return null;
    }

    return 'Historical storage has not returned data yet. Live readings will continue to populate this chart.';
});

const isRefreshing = computed(() => {
    return (
        props.refreshing ||
        locallyRefreshing.value ||
        liveEnergy.loading.value ||
        historyLoading.value
    );
});

const currentPower = computed(() => {
    return Math.max(liveEnergy.watts.value ?? 0, 0);
});

const liveDeviceRows = computed(() => {
    return liveEnergy.data.value?.devices ?? [];
});

const rawPowerDevices = computed(() => {
    return props.devices.filter((device) => {
        return (
            hasPowerCapability(device) ||
            hasLiveEnergyReading(device) ||
            device.power > 0 ||
            device.voltage > 0 ||
            device.current > 0
        );
    });
});

const powerDevices = computed<EnergyDeviceSummary[]>(() => {
    const totalPower = currentPower.value;

    return rawPowerDevices.value
        .map((device) => {
            const livePower = Math.max(
                getLivePower(device),
                0
            );

            return {
                id: device.id,
                name: device.name,
                model: device.model,
                location: device.location,
                online: getLiveOnlineStatus(device),
                power: livePower,
                voltage: averageVoltage.value,
                current: totalCurrent.value,
                share:
                    totalPower > 0
                        ? (livePower / totalPower) * 100
                        : 0
            };
        })
        .sort((first, second) => {
            return second.power - first.power;
        });
});

const onlineMeterCount = computed(() => {
    return powerDevices.value.filter((device) => {
        return device.online;
    }).length;
});

const activeDeviceCount = computed(() => {
    return powerDevices.value.filter((device) => {
        return device.online && device.power > 0;
    }).length;
});

const availability = computed(() => {
    if (powerDevices.value.length === 0) {
        return 0;
    }

    return Math.round(
        (
            onlineMeterCount.value /
            powerDevices.value.length
        ) * 100
    );
});

const highestConsumer = computed(() => {
    return powerDevices.value[0];
});

/*
 * Историческа графика за мощността.
 * Ако има повече от едно устройство, стойностите за еднакъв bucket
 * се сумират.
 */
const chartPoints = computed<EnergyPoint[]>(() => {
    const totalsByBucket = new Map<string, number>();

    for (const row of currentHistory.value.rows.value) {
        if (row.tag !== 'power') {
            continue;
        }

        const bucket = normalizeBucketTimestamp(row.bucket);
        const value = normalizeMetricNumber(row.value);

        if (bucket === null || value === null) {
            continue;
        }

        totalsByBucket.set(
            bucket,
            (totalsByBucket.get(bucket) ?? 0) + Math.max(value, 0)
        );
    }

    const backendPoints = Array.from(totalsByBucket.entries())
        .sort(([firstBucket], [secondBucket]) => {
            return (
                new Date(firstBucket).getTime() -
                new Date(secondBucket).getTime()
            );
        })
        .map(([bucket, value]) => ({
            label: formatHistoryLabel(bucket, period.value),
            value
        }));

    if (backendPoints.length > 0) {
        return backendPoints;
    }

    const periodMilliseconds =
        period.value === '30d'
            ? 30 * DAY_MS
            : period.value === '7d'
                ? 7 * DAY_MS
                : DAY_MS;

    const cutoff = Date.now() - periodMilliseconds;

    return localEnergySamples.value
        .filter((sample) => {
            return new Date(sample.timestamp).getTime() >= cutoff;
        })
        .sort((first, second) => {
            return (
                new Date(first.timestamp).getTime() -
                new Date(second.timestamp).getTime()
            );
        })
        .map((sample) => ({
            label: formatHistoryLabel(sample.timestamp, period.value),
            value: sample.value
        }));
});

/*
 * total_act_energy вече е в kWh.
 * Събираме bucket-ите, за да получим консумацията за периода.
 */
const selectedConsumption = computed(() => {
    return sumConsumption(
        currentHistory.value.rows.value
    );
});

const consumption24Hours = computed(() => {
    return sumConsumption(
        history24Hours.rows.value
    );
});

/*
 * Използваме последния времеви bucket за моментните Voltage/Current KPI.
 */
const averageVoltage = computed(() => {
    const rows = getLatestRowsByTag(
        history24Hours.rows.value,
        'voltage'
    );

    if (rows.length === 0) {
        return 0;
    }

    return rows.reduce(
        (total, row) => {
            const value = normalizeMetricNumber(row.value);

            return value === null
                ? total
                : total + Math.max(value, 0);
        },
        0
    ) / rows.length;
});

const totalCurrent = computed(() => {
    return getLatestRowsByTag(
        history24Hours.rows.value,
        'current'
    ).reduce(
        (total, row) => {
            const value = normalizeMetricNumber(row.value);

            return value === null
                ? total
                : total + Math.max(value, 0);
        },
        0
    );
});

function sumConsumption(
    rows: typeof history24Hours.rows.value
): number {
    return rows
        .filter((row) => {
            return row.tag === 'total_act_energy';
        })
        .reduce((total, row) => {
            const value = normalizeMetricNumber(row.value);

            return value === null
                ? total
                : total + Math.max(value, 0);
        }, 0);
}

function getLatestRowsByTag(
    rows: typeof history24Hours.rows.value,
    tag: 'voltage' | 'current'
) {
    const matchingRows = rows.filter((row) => {
        return row.tag === tag;
    });

    if (matchingRows.length === 0) {
        return [];
    }

    const latestTimestamp = Math.max(
        ...matchingRows.map((row) => {
            return getBucketTime(row.bucket);
        })
    );

    return matchingRows.filter((row) => {
        return (
            getBucketTime(row.bucket) ===
            latestTimestamp
        );
    });
}

function getShellyId(device: Device): string {
    const raw = device.raw as
        | Record<string, unknown>
        | undefined;

    const candidate =
        raw?.shellyID ??
        raw?.shellyId ??
        raw?.shelly_id ??
        raw?.externalId ??
        raw?.external_id ??
        device.id;

    return String(candidate);
}

function getLiveDevice(device: Device) {
    const shellyId = getShellyId(device);

    return liveDeviceRows.value.find((row) => {
        return row.shellyID === shellyId;
    });
}

function getLivePower(device: Device): number {
    return getLiveDevice(device)?.watts ?? 0;
}

function getLiveOnlineStatus(device: Device): boolean {
    return (
        getLiveDevice(device)?.online ??
        device.online
    );
}

function hasLiveEnergyReading(device: Device): boolean {
    return getLiveDevice(device) !== undefined;
}

function hasPowerCapability(device: Device): boolean {
    const rawText = JSON.stringify(
        device.raw ?? {}
    ).toLowerCase();

    const searchableText = [
        device.name,
        device.model,
        rawText
    ]
        .join(' ')
        .toLowerCase();

    return [
        'plug',
        'pm',
        'power',
        'switch',
        'em1',
        'energy'
    ].some((keyword) => {
        return searchableText.includes(keyword);
    });
}

function formatPower(value: number): string {
    if (value >= 1000) {
        return `${(value / 1000).toFixed(2)} kW`;
    }

    return `${value.toFixed(1)} W`;
}

function formatEnergy(value: number): string {
    if (value >= 1000) {
        return `${(value / 1000).toFixed(2)} MWh`;
    }

    if (value < 0.01) {
        return `${value.toFixed(4)} kWh`;
    }

    return `${value.toFixed(2)} kWh`;
}

function formatVoltage(value: number): string {
    return value > 0
        ? `${value.toFixed(1)} V`
        : 'No data';
}

function formatCurrent(value: number): string {
    return value > 0
        ? `${value.toFixed(2)} A`
        : 'No data';
}

function normalizeBucketTimestamp(
    bucket: unknown
): string | null {
    if (typeof bucket === 'string') {
        const timestamp = Date.parse(bucket);
        return Number.isFinite(timestamp)
            ? new Date(timestamp).toISOString()
            : null;
    }

    if (typeof bucket === 'number' && Number.isFinite(bucket)) {
        const milliseconds = bucket < 10_000_000_000
            ? bucket * 1000
            : bucket;

        return new Date(milliseconds).toISOString();
    }

    if (typeof bucket !== 'object' || bucket === null) {
        return null;
    }

    const record = bucket as Record<string, unknown>;

    for (const key of [
        'bucket',
        'timestamp',
        'time',
        'start',
        'from',
        'date',
        'value'
    ]) {
        const normalized = normalizeBucketTimestamp(record[key]);

        if (normalized !== null) {
            return normalized;
        }
    }

    return null;
}

function normalizeMetricNumber(
    value: unknown
): number | null {
    if (typeof value === 'number') {
        return Number.isFinite(value)
            ? value
            : null;
    }

    if (typeof value === 'string') {
        const parsed = Number(value);
        return Number.isFinite(parsed)
            ? parsed
            : null;
    }

    if (typeof value !== 'object' || value === null) {
        return null;
    }

    const record = value as Record<string, unknown>;

    for (const key of [
        'value',
        'avg',
        'average',
        'sum',
        'max',
        'min'
    ]) {
        const normalized = normalizeMetricNumber(record[key]);

        if (normalized !== null) {
            return normalized;
        }
    }

    return null;
}

function getBucketTime(bucket: unknown): number {
    const normalized = normalizeBucketTimestamp(bucket);

    return normalized === null
        ? Number.NEGATIVE_INFINITY
        : new Date(normalized).getTime();
}

function formatHistoryLabel(
    timestamp: string,
    selectedPeriod: EnergyPeriod
): string {
    const date = new Date(timestamp);

    if (!Number.isFinite(date.getTime())) {
        return 'Unknown time';
    }

    if (selectedPeriod === '24h') {
        return date.toLocaleTimeString([], {
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    if (selectedPeriod === '7d') {
        return date.toLocaleDateString([], {
            weekday: 'short',
            hour: '2-digit'
        });
    }

    return date.toLocaleDateString([], {
        day: '2-digit',
        month: 'short',
        hour: '2-digit'
    });
}

function readLocalEnergySamples(): LocalEnergySample[] {
    try {
        const raw = localStorage.getItem(LOCAL_HISTORY_KEY);

        if (!raw) {
            return [];
        }

        const parsed = JSON.parse(raw) as unknown;

        if (!Array.isArray(parsed)) {
            return [];
        }

        const cutoff = Date.now() - 30 * DAY_MS;

        return parsed.filter((sample): sample is LocalEnergySample => {
            if (!sample || typeof sample !== 'object') {
                return false;
            }

            const record = sample as Record<string, unknown>;
            const timestamp = record.timestamp;
            const value = record.value;

            return (
                typeof timestamp === 'string' &&
                Number.isFinite(Date.parse(timestamp)) &&
                Date.parse(timestamp) >= cutoff &&
                typeof value === 'number' &&
                Number.isFinite(value)
            );
        });
    } catch {
        return [];
    }
}

function recordLiveEnergySample(): void {
    const value = currentPower.value;

    if (!Number.isFinite(value)) {
        return;
    }

    const now = Date.now();
    const lastSample = localEnergySamples.value.at(-1);
    const lastTimestamp = lastSample
        ? new Date(lastSample.timestamp).getTime()
        : 0;

    if (now - lastTimestamp < MIN_SAMPLE_INTERVAL_MS) {
        return;
    }

    const cutoff = now - 30 * DAY_MS;

    localEnergySamples.value = [
        ...localEnergySamples.value.filter((sample) => {
            return new Date(sample.timestamp).getTime() >= cutoff;
        }),
        {
            timestamp: new Date(now).toISOString(),
            value: Math.max(value, 0)
        }
    ];

    try {
        localStorage.setItem(
            LOCAL_HISTORY_KEY,
            JSON.stringify(localEnergySamples.value)
        );
    } catch {
        // Local persistence is a best-effort fallback only.
    }
}

watch(
    currentPower,
    () => {
        recordLiveEnergySample();
    },
    { immediate: true }
);

onMounted(() => {
    recordLiveEnergySample();

    localSampleTimer = setInterval(() => {
        recordLiveEnergySample();
    }, MIN_SAMPLE_INTERVAL_MS);
});

onBeforeUnmount(() => {
    if (localSampleTimer !== null) {
        clearInterval(localSampleTimer);
        localSampleTimer = null;
    }
});

async function handleRefresh(): Promise<void> {
    if (locallyRefreshing.value) {
        return;
    }

    locallyRefreshing.value = true;

    try {
        emit('refresh');

        await Promise.all([
            liveEnergy.refresh(),
            history24Hours.refresh(),
            history7Days.refresh(),
            history30Days.refresh()
        ]);
    } finally {
        locallyRefreshing.value = false;
    }
}
</script>

<style scoped src="./EnergyPage.css"></style>