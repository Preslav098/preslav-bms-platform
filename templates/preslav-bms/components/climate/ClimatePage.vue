<template>
    <section class="climate-page">
        <header class="climate-page__header">
            <div>
                <p class="climate-page__eyebrow">
                    Environmental performance
                </p>

                <h2>Climate Monitoring</h2>

                <p class="climate-page__description">
                    Live temperature, humidity and environmental history from
                    Fleet Manager.
                </p>
            </div>

            <button class="climate-page__refresh" type="button" :disabled="isRefreshing" @click="handleRefresh">
                <span :class="{
                    'climate-page__refresh-icon--spinning': isRefreshing
                }">
                    ↻
                </span>

                {{ isRefreshing ? 'Refreshing…' : 'Refresh data' }}
            </button>
        </header>

        <div v-if="!sensor" class="climate-page__empty">
            <div class="climate-page__empty-icon">
                🌡
            </div>

            <h3>No climate sensor found</h3>

            <p>
                Connect a Shelly BLU H&amp;T device and wait for Fleet Manager
                to publish its readings.
            </p>
        </div>

        <template v-else>
            <ClimateSummary :temperature="liveReading.temperature" :humidity="liveReading.humidity"
                :battery="liveReading.battery" :rssi="liveReading.rssi" :online="liveReading.online" />

            <div class="climate-page__content-grid">
                <ClimateChart :points="chartPoints" :loading="historyLoading" :error="historyError" />

                <article class="climate-page__insights">
                    <header>
                        <div>
                            <p>Live insights</p>
                            <h3>Office comfort</h3>
                        </div>

                        <span :class="comfortBadgeClass">
                            {{ overallComfort }}
                        </span>
                    </header>

                    <div class="climate-page__comfort-gauge">
                        <div class="climate-page__comfort-value">
                            <strong>
                                {{ formatTemperature(liveReading.temperature) }}
                            </strong>

                            <span>
                                {{ temperatureComfort }}
                            </span>
                        </div>
                    </div>

                    <div class="climate-page__insight-list">
                        <div>
                            <span>Average temperature</span>

                            <strong>
                                {{ formatTemperature(averageTemperature) }}
                            </strong>
                        </div>

                        <div>
                            <span>24H temperature range</span>

                            <strong>
                                {{ temperatureRangeLabel }}
                            </strong>
                        </div>

                        <div>
                            <span>Average humidity</span>

                            <strong>
                                {{ formatHumidity(averageHumidity) }}
                            </strong>
                        </div>

                        <div>
                            <span>Humidity condition</span>

                            <strong>
                                {{ humidityComfort }}
                            </strong>
                        </div>

                        <div>
                            <span>Sensor battery</span>

                            <strong>
                                {{ formatBattery(liveReading.battery) }}
                            </strong>
                        </div>

                        <div>
                            <span>Last reading</span>

                            <strong>
                                {{ formattedLastSeen }}
                            </strong>
                        </div>
                    </div>
                </article>
            </div>

            <section class="climate-page__devices">
                <header class="climate-page__section-header">
                    <div>
                        <p>Environmental sensors</p>
                        <h3>Climate devices</h3>
                    </div>

                    <span>1 detected</span>
                </header>

                <article class="climate-page__sensor-card">
                    <div class="climate-page__sensor-icon">
                        🌡
                    </div>

                    <div class="climate-page__sensor-main">
                        <div class="climate-page__sensor-heading">
                            <div>
                                <h4>
                                    {{ sensor.name ?? 'Shelly BLU H&T' }}
                                </h4>

                                <p>
                                    {{ sensor.type ?? 'Climate sensor' }}
                                </p>
                            </div>

                            <span :class="{
                                'climate-page__sensor-status--online':
                                    liveReading.online,
                                'climate-page__sensor-status--offline':
                                    !liveReading.online
                            }">
                                {{ liveReading.online ? 'Online' : 'Offline' }}
                            </span>
                        </div>

                        <div class="climate-page__sensor-readings">
                            <div>
                                <span>Temperature</span>

                                <strong>
                                    {{
                                        formatTemperature(
                                            liveReading.temperature
                                        )
                                    }}
                                </strong>
                            </div>

                            <div>
                                <span>Humidity</span>

                                <strong>
                                    {{ formatHumidity(liveReading.humidity) }}
                                </strong>
                            </div>

                            <div>
                                <span>Battery</span>

                                <strong>
                                    {{ formatBattery(liveReading.battery) }}
                                </strong>
                            </div>

                            <div>
                                <span>Signal</span>

                                <strong>
                                    {{
                                        liveReading.rssi !== null
                                            ? `${liveReading.rssi} dBm`
                                            : 'No data'
                                    }}
                                </strong>
                            </div>
                        </div>

                        <div class="climate-page__sensor-footer">
                            <span>
                                ID: {{ sensor.shellyID }}
                            </span>

                            <span>
                                {{ formattedLastSeen }}
                            </span>
                        </div>
                    </div>
                </article>
            </section>
        </template>
    </section>
</template>

<script setup lang="ts">
import {
    computed,
    ref,
    watch
} from 'vue';

import {
    callMethod,
    type HostDevice
} from '@host/index';

import ClimateChart from './ClimateChart.vue';
import ClimateSummary from './ClimateSummary.vue';

import {
    extractBluClimate,
    isBluHTDevice
} from '../../utils/bthome';

import type {
    ClimateChartPoint
} from './ClimateChart.vue';

interface StatusHistoryPoint {
    bucket?: string;
    avgVal?: number | null;
    minVal?: number | null;
    maxVal?: number | null;
}

interface ClimateHistorySample {
    bucket: string;
    temperature: number | null;
    humidity: number | null;
}

interface EnergyHistoryItem {
    bucket: string;
    shellyID: string | null;
    tag: string;
    value: number;
    min?: number | null;
    max?: number | null;
}

const props = withDefaults(
    defineProps<{
        devices: HostDevice[];
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
const LOCAL_HISTORY_INTERVAL_MS = 5 * 60 * 1000;
const LOCAL_HISTORY_PREFIX = 'preslav-bms-climate-history';

const localRefreshing = ref(false);
const historyLoading = ref(false);
const historyError = ref<string | null>(null);
const temperatureHistory = ref<StatusHistoryPoint[]>([]);
const humidityHistory = ref<StatusHistoryPoint[]>([]);
const localHistorySamples = ref<ClimateHistorySample[]>([]);

const sensor = computed(() => {
    return props.devices.find(isBluHTDevice);
});

const liveReading = computed(() => {
    if (!sensor.value) {
        return {
            temperature: null,
            humidity: null,
            battery: null,
            rssi: null,
            lastSeen: null,
            online: false
        };
    }

    return extractBluClimate(sensor.value);
});

const isRefreshing = computed(() => {
    return (
        props.refreshing ||
        localRefreshing.value ||
        historyLoading.value
    );
});

const chartPoints = computed<ClimateChartPoint[]>(() => {
    const buckets = new Map<
        string,
        {
            temperature: number | null;
            humidity: number | null;
        }
    >();

    for (const row of temperatureHistory.value) {
        if (!row.bucket) {
            continue;
        }

        const current = buckets.get(row.bucket) ?? {
            temperature: null,
            humidity: null
        };

        current.temperature = finiteNumber(row.avgVal);
        buckets.set(row.bucket, current);
    }

    for (const row of humidityHistory.value) {
        if (!row.bucket) {
            continue;
        }

        const current = buckets.get(row.bucket) ?? {
            temperature: null,
            humidity: null
        };

        current.humidity = finiteNumber(row.avgVal);
        buckets.set(row.bucket, current);
    }

    for (const sample of localHistorySamples.value) {
        const current = buckets.get(sample.bucket) ?? {
            temperature: null,
            humidity: null
        };

        if (sample.temperature !== null) {
            current.temperature = sample.temperature;
        }

        if (sample.humidity !== null) {
            current.humidity = sample.humidity;
        }

        buckets.set(sample.bucket, current);
    }

    return Array.from(buckets.entries())
        .sort(([firstBucket], [secondBucket]) => {
            return (
                new Date(firstBucket).getTime() -
                new Date(secondBucket).getTime()
            );
        })
        .map(([bucket, values]) => ({
            bucket,
            label: new Date(bucket).toLocaleTimeString([], {
                hour: '2-digit',
                minute: '2-digit'
            }),
            temperature: values.temperature,
            humidity: values.humidity
        }));
});

const temperatureValues = computed(() => {
    return chartPoints.value
        .map((point) => point.temperature)
        .filter((value): value is number => value !== null);
});

const humidityValues = computed(() => {
    return chartPoints.value
        .map((point) => point.humidity)
        .filter((value): value is number => value !== null);
});

const minimumTemperature = computed(() => {
    if (temperatureValues.value.length === 0) {
        return liveReading.value.temperature;
    }

    return Math.min(...temperatureValues.value);
});

const maximumTemperature = computed(() => {
    if (temperatureValues.value.length === 0) {
        return liveReading.value.temperature;
    }

    return Math.max(...temperatureValues.value);
});

const averageTemperature = computed(() => {
    return averageValue(
        temperatureValues.value,
        liveReading.value.temperature
    );
});

const averageHumidity = computed(() => {
    return averageValue(
        humidityValues.value,
        liveReading.value.humidity
    );
});

const temperatureComfort = computed(() => {
    const temperature = liveReading.value.temperature;

    if (temperature === null) {
        return 'No reading';
    }

    if (temperature < 18) {
        return 'Below comfort range';
    }

    if (temperature > 26) {
        return 'Above comfort range';
    }

    return 'Comfortable temperature';
});

const humidityComfort = computed(() => {
    const humidity = liveReading.value.humidity;

    if (humidity === null) {
        return 'No reading';
    }

    if (humidity < 30) {
        return 'Air is too dry';
    }

    if (humidity > 60) {
        return 'Humidity is too high';
    }

    return 'Healthy humidity';
});

const overallComfort = computed(() => {
    const temperature = liveReading.value.temperature;
    const humidity = liveReading.value.humidity;

    if (
        temperature === null ||
        humidity === null
    ) {
        return 'Unknown';
    }

    if (
        temperature >= 18 &&
        temperature <= 26 &&
        humidity >= 30 &&
        humidity <= 60
    ) {
        return 'Comfortable';
    }

    if (
        temperature < 16 ||
        temperature > 29 ||
        humidity < 20 ||
        humidity > 70
    ) {
        return 'Attention';
    }

    return 'Monitor';
});

const comfortBadgeClass = computed(() => ({
    'climate-page__comfort-badge': true,
    'climate-page__comfort-badge--good':
        overallComfort.value === 'Comfortable',
    'climate-page__comfort-badge--warning':
        overallComfort.value === 'Monitor',
    'climate-page__comfort-badge--danger':
        overallComfort.value === 'Attention',
    'climate-page__comfort-badge--unknown':
        overallComfort.value === 'Unknown'
}));

const temperatureRangeLabel = computed(() => {
    if (
        minimumTemperature.value === null ||
        maximumTemperature.value === null
    ) {
        return 'No data';
    }

    return (
        `${minimumTemperature.value.toFixed(1)} – ` +
        `${maximumTemperature.value.toFixed(1)} °C`
    );
});

const formattedLastSeen = computed(() => {
    const lastSeen = liveReading.value.lastSeen;

    if (!lastSeen) {
        return 'Last seen unknown';
    }

    const timestamp = new Date(lastSeen);
    const difference = Date.now() - timestamp.getTime();

    if (difference < 60_000) {
        return 'Updated just now';
    }

    if (difference < 60 * 60_000) {
        const minutes = Math.floor(
            difference / 60_000
        );

        return `Updated ${minutes} min ago`;
    }

    return timestamp.toLocaleString();
});

watch(
    () => sensor.value?.shellyID,
    (shellyID) => {
        temperatureHistory.value = [];
        humidityHistory.value = [];
        historyError.value = null;
        localHistorySamples.value = shellyID
            ? readLocalHistory(shellyID)
            : [];

        if (shellyID) {
            recordLiveReading();
            void refreshHistory();
        }
    },
    {immediate: true}
);

watch(
    () => [
        sensor.value?.shellyID,
        liveReading.value.temperature,
        liveReading.value.humidity,
        liveReading.value.lastSeen
    ] as const,
    () => {
        recordLiveReading();
    }
);

async function refreshHistory(): Promise<void> {
    const shellyID = sensor.value?.shellyID;

    if (!shellyID || historyLoading.value) {
        return;
    }

    historyLoading.value = true;
    historyError.value = null;

    const to = new Date();
    const from = new Date(to.getTime() - DAY_MS);

    try {
        const unified = await loadUnifiedEnvironmentalHistory(
            shellyID,
            from,
            to
        );

        if (
            unified.temperature.length > 0 ||
            unified.humidity.length > 0
        ) {
            temperatureHistory.value = unified.temperature;
            humidityHistory.value = unified.humidity;
        } else {
            const [temperature, humidity] = await Promise.all([
                loadFirstAvailableHistory(
                    shellyID,
                    ['tC'],
                    from,
                    to
                ),
                loadFirstAvailableHistory(
                    shellyID,
                    ['rh'],
                    from,
                    to
                )
            ]);

            temperatureHistory.value = temperature;
            humidityHistory.value = humidity;
        }

        recordLiveReading();
    } catch (error) {
        historyError.value = error instanceof Error
            ? error.message
            : String(error);
    } finally {
        historyLoading.value = false;
    }
}

async function loadUnifiedEnvironmentalHistory(
    shellyID: string,
    from: Date,
    to: Date
): Promise<{
    temperature: StatusHistoryPoint[];
    humidity: StatusHistoryPoint[];
}> {
    const response = await callMethod(
        'energy.query',
        {
            from: from.toISOString(),
            to: to.toISOString(),
            tags: [
                'temperature',
                'humidity'
            ],
            devices: [shellyID],
            bucket: '1 hour',
            perDevice: true
        }
    );

    const items = response.items as EnergyHistoryItem[];

    const toStatusRows = (
        tag: 'temperature' | 'humidity'
    ): StatusHistoryPoint[] => {
        return items
            .filter((item) => {
                return (
                    item.tag === tag &&
                    String(item.shellyID) === String(shellyID) &&
                    Number.isFinite(item.value)
                );
            })
            .map((item) => ({
                bucket: item.bucket,
                avgVal: item.value,
                minVal: item.min ?? item.value,
                maxVal: item.max ?? item.value
            }));
    };

    return {
        temperature: toStatusRows('temperature'),
        humidity: toStatusRows('humidity')
    };
}

async function loadFirstAvailableHistory(
    shellyID: string,
    fields: readonly string[],
    from: Date,
    to: Date
): Promise<StatusHistoryPoint[]> {
    let lastError: unknown = null;

    for (const field of fields) {
        try {
            const response = await callMethod(
                'device.getstatushistory',
                {
                    shellyID,
                    field,
                    from: from.toISOString(),
                    to: to.toISOString()
                }
            );

            if (response.data.length > 0) {
                return response.data;
            }
        } catch (error) {
            lastError = error;
        }
    }

    if (lastError) {
        throw lastError;
    }

    return [];
}

function getLocalHistoryKey(
    shellyID: string
): string {
    return `${LOCAL_HISTORY_PREFIX}:${shellyID}`;
}

function readLocalHistory(
    shellyID: string
): ClimateHistorySample[] {
    try {
        const raw = localStorage.getItem(
            getLocalHistoryKey(shellyID)
        );

        if (!raw) {
            return [];
        }

        const minimumTime = Date.now() - DAY_MS;
        const parsed = JSON.parse(raw) as ClimateHistorySample[];

        return parsed.filter((sample) => {
            return (
                typeof sample.bucket === 'string' &&
                new Date(sample.bucket).getTime() >= minimumTime &&
                (
                    finiteNumber(sample.temperature) !== null ||
                    finiteNumber(sample.humidity) !== null
                )
            );
        });
    } catch (error) {
        console.warn('Failed to read local climate history:', error);
        return [];
    }
}

function recordLiveReading(): void {
    const shellyID = sensor.value?.shellyID;
    const temperature = liveReading.value.temperature;
    const humidity = liveReading.value.humidity;

    if (
        !shellyID ||
        (temperature === null && humidity === null)
    ) {
        return;
    }

    const now = Date.now();
    const samples = readLocalHistory(shellyID);
    const lastSample = samples[samples.length - 1];
    const lastTime = lastSample
        ? new Date(lastSample.bucket).getTime()
        : 0;

    const valuesChanged =
        !lastSample ||
        lastSample.temperature !== temperature ||
        lastSample.humidity !== humidity;

    if (
        !valuesChanged &&
        now - lastTime < LOCAL_HISTORY_INTERVAL_MS
    ) {
        localHistorySamples.value = samples;
        return;
    }

    const nextSamples = [
        ...samples,
        {
            bucket: new Date(now).toISOString(),
            temperature,
            humidity
        }
    ].filter((sample) => {
        return new Date(sample.bucket).getTime() >= now - DAY_MS;
    });

    localHistorySamples.value = nextSamples;

    try {
        localStorage.setItem(
            getLocalHistoryKey(shellyID),
            JSON.stringify(nextSamples)
        );
    } catch (error) {
        console.warn('Failed to persist climate history:', error);
    }
}

function finiteNumber(
    value: unknown
): number | null {
    return (
        typeof value === 'number' &&
        Number.isFinite(value)
    )
        ? value
        : null;
}

function averageValue(
    values: number[],
    fallback: number | null
): number | null {
    if (values.length === 0) {
        return fallback;
    }

    return values.reduce(
        (total, value) => total + value,
        0
    ) / values.length;
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

function formatBattery(
    value: number | null
): string {
    return value === null
        ? 'No data'
        : `${value.toFixed(0)}%`;
}

async function handleRefresh(): Promise<void> {
    if (localRefreshing.value) {
        return;
    }

    localRefreshing.value = true;

    try {
        emit('refresh');
        await refreshHistory();
    } finally {
        localRefreshing.value = false;
    }
}
</script>

<style scoped src="./ClimatePage.css"></style>