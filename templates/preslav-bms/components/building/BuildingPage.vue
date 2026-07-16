<template>
    <section class="building-page">
        <header class="building-page__header">
            <div>
                <p class="building-page__eyebrow">
                    Building overview
                </p>

                <h2>Building</h2>

                <p class="building-page__description">
                    Overview of all configured floors, devices and current
                    operational status.
                </p>
            </div>

            <button class="building-page__floors-button" type="button" @click="$emit('open-floors')">
                Open floor plans
                <span aria-hidden="true">→</span>
            </button>
        </header>

        <BuildingScene3D
            :floors="floors"
            @select-floor="$emit('select-floor', $event)"
        />

        <section class="building-page__statistics">
            <article class="building-page__stat-card">
                <span class="building-page__stat-icon">
                    🏢
                </span>

                <div>
                    <span>Floors</span>
                    <strong>{{ floors.length }}</strong>
                </div>
            </article>

            <article class="building-page__stat-card">
                <span class="building-page__stat-icon">
                    📡
                </span>

                <div>
                    <span>Total devices</span>
                    <strong>{{ devices.length }}</strong>
                </div>
            </article>

            <article class="building-page__stat-card">
                <span class="
                        building-page__stat-icon
                        building-page__stat-icon--online
                    ">
                    ✓
                </span>

                <div>
                    <span>Online</span>

                    <strong class="building-page__value--online">
                        {{ onlineCount }}
                    </strong>
                </div>
            </article>

            <article class="building-page__stat-card">
                <span class="
                        building-page__stat-icon
                        building-page__stat-icon--offline
                    ">
                    !
                </span>

                <div>
                    <span>Requires attention</span>

                    <strong :class="{
                        'building-page__value--offline':
                            attentionCount > 0
                    }">
                        {{ attentionCount }}
                    </strong>
                </div>
            </article>
        </section>

        <section v-if="floors.length === 0" class="building-page__empty">
            <span aria-hidden="true">🏢</span>

            <h3>No building floors configured</h3>

            <p>
                Create Fleet Manager groups to represent the floors in your
                building.
            </p>

            <button type="button" @click="$emit('open-floors')">
                Open floor plans
            </button>
        </section>

        <section v-else class="building-page__floors">
            <header class="building-page__section-header">
                <div>
                    <p>Building structure</p>
                    <h3>Floors</h3>
                </div>

                <span>
                    {{ floors.length }}
                    {{ floors.length === 1 ? 'floor' : 'floors' }}
                </span>
            </header>

            <div class="building-page__floor-grid">
                <BuildingFloorCard v-for="floor in floors" :key="String(floor.id)" :floor="floor"
                    @open="$emit('select-floor', floor)" />
            </div>
        </section>
    </section>
</template>

<script setup lang="ts">
import { computed } from 'vue';

import BuildingFloorCard from './BuildingFloorCard.vue';
import BuildingScene3D from './BuildingScene3D.vue';

import type { Device } from '../../models/Device';
import type { Floor } from '../../models/Floor';

const props = defineProps<{
    floors: Floor[];
    devices: Device[];
}>();

defineEmits<{
    'open-floors': [];
    'select-floor': [floor: Floor];
}>();

const onlineCount = computed(() => {
    return props.devices.filter(
        (device) => device.status === 'online'
    ).length;
});

const attentionCount = computed(() => {
    return props.devices.filter(
        (device) =>
            device.status === 'offline' ||
            device.status === 'warning'
    ).length;
});
</script>

<style scoped src="./BuildingPage.css"></style>