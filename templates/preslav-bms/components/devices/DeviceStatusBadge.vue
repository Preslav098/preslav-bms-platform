<template>
    <span class="device-status-badge" :class="statusClass">
        <span class="status-dot"></span>

        {{ statusLabel }}
    </span>
</template>

<script setup lang="ts">
import { computed } from "vue"
import type { DeviceStatus } from "../../models/Device"

const props = defineProps<{
    status: DeviceStatus
}>()

const statusClass = computed(() => `device-status-badge--${props.status}`)

const statusLabel = computed(() => {
    switch (props.status) {
        case "online":
            return "Online"
        case "offline":
            return "Offline"
        case "warning":
            return "Warning"
    }
})
</script>

<style scoped src="./DeviceStatusBadge.css"></style>