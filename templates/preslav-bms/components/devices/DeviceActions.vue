<template>
    <div class="device-actions">
        <button type="button" class="device-action-button device-action-button--secondary" @click="emit('details')">
            Details
        </button>

        <button type="button" class="device-action-button device-action-button--primary" @click="emit('restart')">
            Restart
        </button>
    </div>
</template>

<script setup lang="ts">
const emit = defineEmits<{
    details: []
    restart: []
}>()
</script>

<style scoped src="./DeviceActions.css"></style>