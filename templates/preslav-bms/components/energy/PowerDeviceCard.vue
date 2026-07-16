<template>
    <article class="power-device-card">
        <header>
            <span class="power-device-card__icon">ϟ</span>
            <div>
                <strong>{{ device.name }}</strong>
                <small>{{ device.model }}</small>
            </div>
            <span class="power-device-card__status" :class="{
                'power-device-card__status--online': device.online
            }">
                {{ device.online ? 'Online' : 'Offline' }}
            </span>
        </header>

        <div class="power-device-card__power">
            <small>Current power</small>
            <strong>{{ formatPower(device.power) }}</strong>
        </div>

        <div class="power-device-card__meter">
            <span :style="{ width: `${device.share}%` }"></span>
        </div>

        <div class="power-device-card__metrics">
            <div>
                <small>Voltage</small>
                <strong>{{ device.voltage.toFixed(1) }} V</strong>
            </div>
            <div>
                <small>Current</small>
                <strong>{{ device.current.toFixed(2) }} A</strong>
            </div>
            <div>
                <small>Share</small>
                <strong>{{ device.share.toFixed(0) }}%</strong>
            </div>
        </div>

        <footer>
            <span>{{ device.location }}</span>
            <span>{{ device.online ? 'Live reading' : 'Last known value' }}</span>
        </footer>
    </article>
</template>

<script setup lang="ts">
import type { EnergyDeviceSummary } from '../../models/Energy';

defineProps<{
    device: EnergyDeviceSummary;
}>();

function formatPower(value: number): string {
    return value >= 1000
        ? `${(value / 1000).toFixed(2)} kW`
        : `${value.toFixed(1)} W`;
}
</script>

<style scoped src="./PowerDeviceCard.css"></style>
