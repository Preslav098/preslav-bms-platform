<template>
    <header class="dashboard-header">
        <div>
            <p class="dashboard-header__eyebrow">
                Operations overview
            </p>

            <h2>Building dashboard</h2>

            <p class="dashboard-header__description">
                Real-time overview of devices, floors and building systems.
            </p>
        </div>

        <button class="dashboard-header__refresh" type="button" :disabled="refreshing" @click="$emit('refresh')">
            <span class="dashboard-header__refresh-icon" :class="{
                'dashboard-header__refresh-icon--spinning': refreshing
            }">
                ↻
            </span>

            {{ refreshing ? 'Refreshing…' : 'Refresh data' }}
        </button>
    </header>
</template>

<script setup lang="ts">
defineProps<{
    refreshing: boolean;
}>();

defineEmits<{
    refresh: [];
}>();
</script>

<style scoped src="./DashboardHeader.css"></style>