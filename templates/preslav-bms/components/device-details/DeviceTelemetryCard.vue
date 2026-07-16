<template>
    <div class="telemetry-card" :class="`telemetry-card--${color}`">
        <span>{{ title }}</span>

        <strong>{{ value }}</strong>
    </div>
</template>

<script setup lang="ts">
defineProps<{
    title: string;
    value: string | number;
    color: string;
}>();
</script>

<style scoped src="./DeviceTelemetryCard.css"></style>