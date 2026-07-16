<template>
    <article class="energy-chart">
        <header class="energy-chart__header">
            <div>
                <p>Consumption trend</p>
                <h3>Power profile</h3>
            </div>

            <div class="energy-chart__periods" aria-label="Chart period">
                <button v-for="option in periodOptions" :key="option.id" type="button" :class="{
                    'energy-chart__period--active': period === option.id
                }" @click="$emit('update:period', option.id)">
                    {{ option.label }}
                </button>
            </div>
        </header>

        <div v-if="points.length === 0" class="energy-chart__empty">
            No power measurements are available yet.
        </div>

        <div v-else class="energy-chart__body">
            <div class="energy-chart__value-row">
                <div>
                    <small>Peak load</small>
                    <strong>{{ formatPower(peakValue) }}</strong>
                </div>
                <div>
                    <small>Estimated energy</small>
                    <strong>{{ estimatedEnergy.toFixed(2) }} kWh</strong>
                </div>
            </div>

            <svg class="energy-chart__svg" viewBox="0 0 760 260" role="img" aria-label="Estimated power trend chart">
                <defs>
                    <linearGradient id="energy-area-gradient" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stop-color="#60a5fa" stop-opacity="0.34" />
                        <stop offset="100%" stop-color="#60a5fa" stop-opacity="0" />
                    </linearGradient>
                </defs>

                <line v-for="line in 5" :key="line" x1="24" x2="736" :y1="line * 43" :y2="line * 43"
                    class="energy-chart__grid-line" />

                <path :d="areaPath" fill="url(#energy-area-gradient)" />
                <polyline :points="linePoints" class="energy-chart__line" />

                <circle v-for="(point, index) in chartCoordinates" :key="`${point.x}-${point.y}`" :cx="point.x"
                    :cy="point.y" r="4" class="energy-chart__point">
                    <title>{{ formatLabel(points[index]?.label) }}: {{ formatPower(points[index]?.value ?? 0) }}</title>
                </circle>
            </svg>

            <div class="energy-chart__labels">
                <span
                    v-for="(point, index) in displayLabels"
                    :key="`${formatLabel(point.label)}-${index}`"
                >
                    {{ formatLabel(point.label) }}
                </span>
            </div>

            <p class="energy-chart__note">
                The current release derives the trend from live readings. Historical Fleet Manager queries can replace this
                dataset without changing the chart component.
            </p>
        </div>
    </article>
</template>

<script setup lang="ts">
import { computed } from 'vue';

import type {
    EnergyPeriod,
    EnergyPoint
} from '../../models/Energy';

const props = defineProps<{
    points: EnergyPoint[];
    period: EnergyPeriod;
}>();

defineEmits<{
    'update:period': [period: EnergyPeriod];
}>();

const periodOptions: Array<{
    id: EnergyPeriod;
    label: string;
}> = [
    { id: '24h', label: '24H' },
    { id: '7d', label: '7D' },
    { id: '30d', label: '30D' }
];

const peakValue = computed(() => {
    return Math.max(0, ...props.points.map((point) => point.value));
});

const estimatedEnergy = computed(() => {
    if (props.points.length === 0) {
        return 0;
    }

    const averagePower = props.points.reduce(
        (total, point) => total + point.value,
        0
    ) / props.points.length;

    const hours = props.period === '24h'
        ? 24
        : props.period === '7d'
            ? 24 * 7
            : 24 * 30;

    return (averagePower * hours) / 1000;
});

const chartCoordinates = computed(() => {
    const width = 712;
    const height = 205;
    const left = 24;
    const top = 20;
    const maxValue = Math.max(peakValue.value, 1);
    const step = props.points.length > 1
        ? width / (props.points.length - 1)
        : 0;

    return props.points.map((point, index) => ({
        x: left + (index * step),
        y: top + height - ((point.value / maxValue) * height)
    }));
});

const linePoints = computed(() => {
    return chartCoordinates.value
        .map((point) => `${point.x},${point.y}`)
        .join(' ');
});

const areaPath = computed(() => {
    if (chartCoordinates.value.length === 0) {
        return '';
    }

    const first = chartCoordinates.value[0];
    const last = chartCoordinates.value[chartCoordinates.value.length - 1];
    const points = chartCoordinates.value
        .map((point) => `L ${point.x} ${point.y}`)
        .join(' ');

    return `M ${first.x} 240 ${points} L ${last.x} 240 Z`;
});

const displayLabels = computed(() => {
    if (props.points.length <= 6) {
        return props.points;
    }

    const lastIndex = props.points.length - 1;
    const indexes = [
        0,
        Math.round(lastIndex * 0.25),
        Math.round(lastIndex * 0.5),
        Math.round(lastIndex * 0.75),
        lastIndex
    ];

    return indexes.map((index) => props.points[index]);
});

function formatLabel(value: unknown): string {
    if (typeof value === 'string') {
        return value;
    }

    if (typeof value === 'number' && Number.isFinite(value)) {
        return String(value);
    }

    return 'Unknown time';
}

function formatPower(value: number): string {
    return value >= 1000
        ? `${(value / 1000).toFixed(2)} kW`
        : `${value.toFixed(1)} W`;
}
</script>

<style scoped src="./EnergyChart.css"></style>
