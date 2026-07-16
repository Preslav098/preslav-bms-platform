<template>
    <header class="overview-header">
        <div>
            <p class="overview-header__eyebrow">
                Building operations
            </p>

            <h1>Building Overview</h1>

            <p class="overview-header__description">
                Live operational status, environmental conditions and
                device health across the building.
            </p>
        </div>

        <div class="overview-header__actions">
            <div class="overview-header__status">
                <span class="overview-header__status-dot" :class="{
                    'overview-header__status-dot--warning':
                        alertCount > 0
                }" aria-hidden="true"></span>

                <span>
                    {{
                        alertCount > 0
                            ? `${alertCount} active alerts`
                            : 'Building operating normally'
                    }}
                </span>
            </div>

            <button class="overview-header__refresh" type="button" :disabled="refreshing" @click="$emit('refresh')">
                <span class="overview-header__refresh-icon" aria-hidden="true">
                    ↻
                </span>

                <span>Refresh</span>
            </button>
        </div>
    </header>
</template>

<script setup lang="ts">
withDefaults(
    defineProps<{
        refreshing?: boolean;
        alertCount?: number;
    }>(),
    {
        refreshing: false,
        alertCount: 0
    }
);

defineEmits<{
    refresh: [];
}>();
</script>

<style scoped src="./OverviewHeader.css"></style>