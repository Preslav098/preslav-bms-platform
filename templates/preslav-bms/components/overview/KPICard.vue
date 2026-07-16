<template>
    <article
        class="kpi-card"
        :class="`kpi-card--${tone}`"
    >
        <div class="kpi-card__top">
            <span
                class="kpi-card__icon"
                aria-hidden="true"
            >
                {{ icon }}
            </span>

            <span
                v-if="status"
                class="kpi-card__status"
            >
                {{ status }}
            </span>
        </div>

        <div class="kpi-card__content">
            <p>{{ label }}</p>

            <strong>
                {{ value }}
            </strong>

            <span>{{ description }}</span>
        </div>

        <div
            v-if="trend"
            class="kpi-card__trend"
        >
            {{ trend }}
        </div>
    </article>
</template>

<script setup lang="ts">
export type KPITone =
    | 'blue'
    | 'green'
    | 'orange'
    | 'red'
    | 'purple'
    | 'cyan';

withDefaults(
    defineProps<{
        label: string;
        value: string;
        description: string;
        icon: string;
        tone?: KPITone;
        status?: string;
        trend?: string;
    }>(),
    {
        tone: 'blue',
        status: '',
        trend: ''
    }
);
</script>

<style scoped src="./KPICard.css"></style>
