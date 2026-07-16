<template>
    <div class="energy-summary">
        <article class="energy-summary__card">
            <span class="energy-summary__icon">ϟ</span>
            <div>
                <small>Current load</small>
                <strong>{{ formatPower(currentPower) }}</strong>
                <span>{{ activeDevices }} active devices</span>
            </div>
        </article>

        <article class="energy-summary__card">
            <span class="energy-summary__icon energy-summary__icon--blue">∿</span>
            <div>
                <small>Average voltage</small>
                <strong>{{ formatVoltage(averageVoltage) }}</strong>
                <span>Live Fleet Manager data</span>
            </div>
        </article>

        <article class="energy-summary__card">
            <span class="energy-summary__icon energy-summary__icon--purple">↯</span>
            <div>
                <small>Total current</small>
                <strong>{{ formatCurrent(totalCurrent) }}</strong>
                <span>Across online meters</span>
            </div>
        </article>

        <article class="energy-summary__card">
            <span class="energy-summary__icon energy-summary__icon--green">◎</span>
            <div>
                <small>Online meters</small>
                <strong>{{ onlineMeters }}/{{ totalMeters }}</strong>
                <span>{{ availability }}% availability</span>
            </div>
        </article>
    </div>
</template>

<script setup lang="ts">
defineProps<{
    currentPower: number;
    averageVoltage: number;
    totalCurrent: number;
    activeDevices: number;
    onlineMeters: number;
    totalMeters: number;
    availability: number;
}>();

function formatPower(value: number): string {
    if (value >= 1000) {
        return `${(value / 1000).toFixed(2)} kW`;
    }

    return `${value.toFixed(1)} W`;
}

function formatVoltage(value: number): string {
    return `${value.toFixed(1)} V`;
}

function formatCurrent(value: number): string {
    return `${value.toFixed(2)} A`;
}
</script>

<style scoped src="./EnergySummary.css"></style>
