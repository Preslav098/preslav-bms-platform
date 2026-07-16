<template>
    <article class="building-floor-card" :class="{
        'building-floor-card--attention':
            attentionCount > 0
    }">
        <header class="building-floor-card__header">
            <span class="building-floor-card__icon">
                {{ floorInitial }}
            </span>

            <div class="building-floor-card__identity">
                <h4>{{ floor.name }}</h4>
                <p>{{ floor.description }}</p>
            </div>

            <span class="building-floor-card__status" :class="{
                'building-floor-card__status--healthy':
                    attentionCount === 0
            }">
                {{
                    attentionCount === 0
                        ? 'Operational'
                        : `${attentionCount} alert${attentionCount === 1 ? '' : 's'
                        }`
                }}
            </span>
        </header>

        <section class="building-floor-card__statistics">
            <article>
                <span>Total</span>
                <strong>{{ floor.devices.length }}</strong>
            </article>

            <article>
                <span>Online</span>
                <strong class="building-floor-card__online">
                    {{ onlineCount }}
                </strong>
            </article>

            <article>
                <span>Offline</span>
                <strong :class="{
                    'building-floor-card__offline':
                        offlineCount > 0
                }">
                    {{ offlineCount }}
                </strong>
            </article>

            <article>
                <span>Warning</span>
                <strong :class="{
                    'building-floor-card__warning':
                        warningCount > 0
                }">
                    {{ warningCount }}
                </strong>
            </article>
        </section>

        <div class="building-floor-card__availability">
            <div>
                <span>Device availability</span>
                <strong>{{ availabilityPercentage }}%</strong>
            </div>

            <div class="building-floor-card__progress">
                <span :style="{
                    width: `${availabilityPercentage}%`
                }"></span>
            </div>
        </div>

        <footer class="building-floor-card__footer">
            <span>
                {{ floor.plan.imageUrl
                    ? 'Floor plan uploaded'
                    : 'No floor plan uploaded' }}
            </span>

            <button type="button" @click="$emit('open')">
                View floor
                <span aria-hidden="true">→</span>
            </button>
        </footer>
    </article>
</template>

<script setup lang="ts">
import { computed } from 'vue';

import type { Floor } from '../../models/Floor';

const props = defineProps<{
    floor: Floor;
}>();

defineEmits<{
    open: [];
}>();

const onlineCount = computed(() => {
    return props.floor.devices.filter(
        (device) => device.status === 'online'
    ).length;
});

const offlineCount = computed(() => {
    return props.floor.devices.filter(
        (device) => device.status === 'offline'
    ).length;
});

const warningCount = computed(() => {
    return props.floor.devices.filter(
        (device) => device.status === 'warning'
    ).length;
});

const attentionCount = computed(() => {
    return offlineCount.value + warningCount.value;
});

const availabilityPercentage = computed(() => {
    if (props.floor.devices.length === 0) {
        return 0;
    }

    return Math.round(
        (
            onlineCount.value /
            props.floor.devices.length
        ) * 100
    );
});

const floorInitial = computed(() => {
    const name = props.floor.name.trim();

    return name
        ? name.charAt(0).toUpperCase()
        : 'F';
});
</script>

<style scoped src="./BuildingFloorCard.css"></style>