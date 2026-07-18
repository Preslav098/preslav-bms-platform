<template>
    <section class="device-toolbar">
        <div class="device-toolbar__summary">
            <strong>{{ visibleCount }}</strong>
            <span>
                {{ visibleCount === 1 ? 'device shown' : 'devices shown' }}
            </span>
        </div>

        <div class="device-toolbar__actions">
            <button
                class="device-toolbar__button device-toolbar__button--manage"
                type="button"
                @click="$emit('manage')"
            >
                <span aria-hidden="true">＋</span>
                Add devices
                <b v-if="pendingCount > 0">{{ pendingCount }}</b>
            </button>

            <label class="device-toolbar__sort">
                <span>Sort by</span>

                <select :value="sort" aria-label="Sort devices" @change="handleSortChange">
                    <option value="name-asc">Name A–Z</option>
                    <option value="name-desc">Name Z–A</option>
                    <option value="status">Status</option>
                    <option value="power-desc">Highest power</option>
                    <option value="temperature-desc">
                        Highest temperature
                    </option>
                </select>
            </label>

            <button class="device-toolbar__button" type="button" :disabled="devices.length === 0"
                @click="$emit('export')">
                <span aria-hidden="true">⇩</span>
                Export CSV
            </button>

            <button class="
                    device-toolbar__button
                    device-toolbar__button--primary
                " type="button" :disabled="refreshing" @click="$emit('refresh')">
                <span class="device-toolbar__refresh-icon" :class="{
                    'device-toolbar__refresh-icon--spinning':
                        refreshing
                }" aria-hidden="true">
                    ↻
                </span>

                {{ refreshing ? 'Refreshing…' : 'Refresh' }}
            </button>
        </div>
    </section>
</template>

<script setup lang="ts">
import type { Device } from '../../models/Device';

export type DeviceSort =
    | 'name-asc'
    | 'name-desc'
    | 'status'
    | 'power-desc'
    | 'temperature-desc';

defineProps<{
    devices: Device[];
    visibleCount: number;
    sort: DeviceSort;
    refreshing: boolean;
    pendingCount?: number;
}>();

const emit = defineEmits<{
    'update:sort': [value: DeviceSort];
    export: [];
    refresh: [];
    manage: [];
}>();

function handleSortChange(event: Event): void {
    const select = event.target as HTMLSelectElement;

    emit(
        'update:sort',
        select.value as DeviceSort
    );
}
</script>

<style scoped src="./DeviceToolbar.css"></style>