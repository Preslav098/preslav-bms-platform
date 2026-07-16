<template>
    <section class="climate-summary">
        <article class="climate-summary__card">
            <div class="climate-summary__icon">🌡</div>

            <div>
                <span>Temperature</span>
                <strong>{{ formatTemperature(temperature) }}</strong>
                <small>{{ temperatureStatus }}</small>
            </div>
        </article>

        <article class="climate-summary__card">
            <div class="climate-summary__icon">💧</div>

            <div>
                <span>Humidity</span>
                <strong>{{ formatHumidity(humidity) }}</strong>
                <small>{{ humidityStatus }}</small>
            </div>
        </article>

        <article class="climate-summary__card">
            <div class="climate-summary__icon">🔋</div>

            <div>
                <span>Battery</span>
                <strong>{{ formatBattery(battery) }}</strong>
                <small>{{ batteryStatus }}</small>
            </div>
        </article>

        <article class="climate-summary__card">
            <div class="climate-summary__icon">◉</div>

            <div>
                <span>Sensor status</span>

                <strong :class="{
                    'climate-summary__online': online,
                    'climate-summary__offline': !online
                }">
                    {{ online ? 'Online' : 'Offline' }}
                </strong>

                <small>
                    {{ rssi !== null ? `${rssi} dBm` : 'Signal unavailable' }}
                </small>
            </div>
        </article>
    </section>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
    temperature: number | null;
    humidity: number | null;
    battery: number | null;
    rssi: number | null;
    online: boolean;
}>();

const temperatureStatus = computed(() => {
    if (props.temperature === null) {
        return 'No reading';
    }

    if (props.temperature < 18) {
        return 'Below comfort range';
    }

    if (props.temperature > 26) {
        return 'Above comfort range';
    }

    return 'Comfortable';
});

const humidityStatus = computed(() => {
    if (props.humidity === null) {
        return 'No reading';
    }

    if (props.humidity < 30) {
        return 'Dry air';
    }

    if (props.humidity > 60) {
        return 'High humidity';
    }

    return 'Healthy range';
});

const batteryStatus = computed(() => {
    if (props.battery === null) {
        return 'No reading';
    }

    if (props.battery < 20) {
        return 'Replace battery soon';
    }

    return 'Battery healthy';
});

function formatTemperature(value: number | null): string {
    return value === null ? '—' : `${value.toFixed(1)} °C`;
}

function formatHumidity(value: number | null): string {
    return value === null ? '—' : `${value.toFixed(0)}%`;
}

function formatBattery(value: number | null): string {
    return value === null ? '—' : `${value.toFixed(0)}%`;
}
</script>

<style scoped src="./ClimateSummary.css"></style>