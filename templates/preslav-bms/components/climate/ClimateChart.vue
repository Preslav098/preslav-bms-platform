<template>
    <article class="climate-chart">
        <header class="climate-chart__header">
            <div>
                <p>Environmental history</p>
                <h3>Last 24 hours</h3>
            </div>

            <div class="climate-chart__legend">
                <span>
                    <i class="climate-chart__legend-dot climate-chart__legend-dot--temperature"></i>
                    Temperature
                </span>

                <span>
                    <i class="climate-chart__legend-dot climate-chart__legend-dot--humidity"></i>
                    Humidity
                </span>
            </div>
        </header>

        <div v-if="loading" class="climate-chart__message">
            Loading climate history…
        </div>

        <div v-else-if="error" class="climate-chart__message climate-chart__message--error">
            {{ error }}
        </div>

        <div v-else-if="points.length === 0" class="climate-chart__message">
            Waiting for the first climate reading…
        </div>

        <div v-else class="climate-chart__canvas">
            <svg class="climate-chart__svg" viewBox="0 0 900 320" preserveAspectRatio="none" role="img"
                aria-label="Temperature and humidity history">
                <line v-for="gridY in gridLines" :key="gridY" x1="45" :y1="gridY" x2="875" :y2="gridY"
                    class="climate-chart__grid-line" />

                <polyline v-if="temperaturePolyline" :points="temperaturePolyline"
                    class="climate-chart__line climate-chart__line--temperature" />

                <polyline v-if="humidityPolyline" :points="humidityPolyline"
                    class="climate-chart__line climate-chart__line--humidity" />

                <g v-for="point in renderedPoints" :key="point.bucket">
                    <circle v-if="point.temperatureY !== null" :cx="point.x" :cy="point.temperatureY" r="4"
                        class="climate-chart__dot climate-chart__dot--temperature" />

                    <circle v-if="point.humidityY !== null" :cx="point.x" :cy="point.humidityY" r="4"
                        class="climate-chart__dot climate-chart__dot--humidity" />
                </g>
            </svg>

            <div class="climate-chart__labels">
                <span v-for="point in visibleLabels" :key="point.bucket">
                    {{ point.label }}
                </span>
            </div>
        </div>
    </article>
</template>

<script setup lang="ts">
import { computed } from 'vue';

export interface ClimateChartPoint {
    bucket: string;
    label: string;
    temperature: number | null;
    humidity: number | null;
}

const props = defineProps<{
    points: ClimateChartPoint[];
    loading?: boolean;
    error?: string | null;
}>();

const WIDTH_START = 55;
const WIDTH_END = 865;
const HEIGHT_TOP = 30;
const HEIGHT_BOTTOM = 270;

const gridLines = [
    30,
    90,
    150,
    210,
    270
];

const temperatureValues = computed(() => {
    return props.points
        .map((point) => point.temperature)
        .filter((value): value is number => value !== null);
});

const humidityValues = computed(() => {
    return props.points
        .map((point) => point.humidity)
        .filter((value): value is number => value !== null);
});

const temperatureRange = computed(() => {
    return createRange(
        temperatureValues.value,
        15,
        30
    );
});

const humidityRange = computed(() => {
    return createRange(
        humidityValues.value,
        20,
        80
    );
});

const renderedPoints = computed(() => {
    const count = Math.max(props.points.length - 1, 1);

    return props.points.map((point, index) => {
        const x =
            WIDTH_START +
            ((WIDTH_END - WIDTH_START) * index) / count;

        return {
            ...point,
            x,
            temperatureY:
                point.temperature === null
                    ? null
                    : scaleY(
                        point.temperature,
                        temperatureRange.value.min,
                        temperatureRange.value.max
                    ),
            humidityY:
                point.humidity === null
                    ? null
                    : scaleY(
                        point.humidity,
                        humidityRange.value.min,
                        humidityRange.value.max
                    )
        };
    });
});

const temperaturePolyline = computed(() => {
    return renderedPoints.value
        .filter((point) => point.temperatureY !== null)
        .map((point) => `${point.x},${point.temperatureY}`)
        .join(' ');
});

const humidityPolyline = computed(() => {
    return renderedPoints.value
        .filter((point) => point.humidityY !== null)
        .map((point) => `${point.x},${point.humidityY}`)
        .join(' ');
});

const visibleLabels = computed(() => {
    if (props.points.length <= 6) {
        return props.points;
    }

    const step = Math.ceil(props.points.length / 6);

    return props.points.filter((_, index) => {
        return (
            index % step === 0 ||
            index === props.points.length - 1
        );
    });
});

function createRange(
    values: number[],
    fallbackMin: number,
    fallbackMax: number
): {
    min: number;
    max: number;
} {
    if (values.length === 0) {
        return {
            min: fallbackMin,
            max: fallbackMax
        };
    }

    const minimum = Math.min(...values);
    const maximum = Math.max(...values);
    const padding = Math.max(
        (maximum - minimum) * 0.2,
        1
    );

    return {
        min: minimum - padding,
        max: maximum + padding
    };
}

function scaleY(
    value: number,
    min: number,
    max: number
): number {
    if (max === min) {
        return (HEIGHT_TOP + HEIGHT_BOTTOM) / 2;
    }

    const ratio = (value - min) / (max - min);

    return (
        HEIGHT_BOTTOM -
        ratio * (HEIGHT_BOTTOM - HEIGHT_TOP)
    );
}
</script>

<style scoped src="./ClimateChart.css"></style>