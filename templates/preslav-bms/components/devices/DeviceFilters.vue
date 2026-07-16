<template>
    <section class="device-filters">
        <label class="device-filters__search">
            <span class="device-filters__search-icon" aria-hidden="true">
                ⌕
            </span>

            <input :value="search" type="search" placeholder="Search devices..." aria-label="Search devices" @input="
                $emit(
                    'update:search',
                    ($event.target as HTMLInputElement).value
                )
                " />
        </label>

        <select class="device-filters__status" :value="status" aria-label="Filter devices by status" @change="
            $emit(
                'update:status',
                ($event.target as HTMLSelectElement)
                    .value as DeviceStatusFilter
            )
            ">
            <option value="all">All statuses</option>
            <option value="online">Online</option>
            <option value="offline">Offline</option>
            <option value="warning">Warning</option>
        </select>

        <button class="device-filters__reset" type="button" :disabled="search === '' && status === 'all'"
            @click="resetFilters">
            Reset
        </button>
    </section>
</template>

<script setup lang="ts">
import type { DeviceStatusFilter } from '../../models/Device';

const props = defineProps<{
    search: string;
    status: DeviceStatusFilter;
}>();

const emit = defineEmits<{
    'update:search': [value: string];
    'update:status': [value: DeviceStatusFilter];
}>();

function resetFilters(): void {
    emit('update:search', '');
    emit('update:status', 'all');
}
</script>

<style scoped src="./DeviceFilters.css"></style>