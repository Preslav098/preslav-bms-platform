<template>
    <section class="device-empty-state">
        <span class="device-empty-state__icon" aria-hidden="true">
            📡
        </span>

        <h3>{{ title }}</h3>

        <p>{{ description }}</p>

        <div class="device-empty-state__actions">
            <button v-if="filtered" type="button" @click="$emit('reset')">
                Reset filters
            </button>

            <button class="device-empty-state__primary" type="button" :disabled="refreshing" @click="$emit('refresh')">
                {{ refreshing ? 'Refreshing…' : 'Refresh devices' }}
            </button>
        </div>
    </section>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
    filtered: boolean;
    refreshing: boolean;
}>();

defineEmits<{
    reset: [];
    refresh: [];
}>();

const title = computed(() => {
    return props.filtered
        ? 'No matching devices'
        : 'No devices available';
});

const description = computed(() => {
    return props.filtered
        ? 'Try another search term or reset the selected status filter.'
        : 'Devices will appear here after they are connected and available through Fleet Manager.';
});
</script>

<style scoped src="./DeviceEmptyState.css"></style>