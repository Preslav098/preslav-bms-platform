<template>
    <section class="quick-actions">
        <header class="quick-actions__header">
            <div>
                <p class="quick-actions__eyebrow">
                    Navigation
                </p>

                <h3>Quick actions</h3>
            </div>
        </header>

        <div class="quick-actions__grid">
            <button class="quick-actions__item" type="button" @click="$emit('open-devices')">
                <span class="quick-actions__icon">📡</span>

                <span>
                    <strong>Devices</strong>
                    <small>Inspect building devices</small>
                </span>

                <span class="quick-actions__arrow">→</span>
            </button>

            <button class="quick-actions__item" type="button" @click="$emit('open-floors')">
                <span class="quick-actions__icon">🗺️</span>

                <span>
                    <strong>Floor plans</strong>
                    <small>Open building schematics</small>
                </span>

                <span class="quick-actions__arrow">→</span>
            </button>

            <button class="quick-actions__item" type="button" @click="$emit('open-energy')">
                <span class="quick-actions__icon">⚡</span>

                <span>
                    <strong>Energy</strong>
                    <small>View consumption data</small>
                </span>

                <span class="quick-actions__arrow">→</span>
            </button>

            <button class="quick-actions__item" type="button" @click="$emit('open-climate')">
                <span class="quick-actions__icon">🌡️</span>

                <span>
                    <strong>Climate</strong>
                    <small>Temperature and humidity</small>
                </span>

                <span class="quick-actions__arrow">→</span>
            </button>
        </div>
    </section>
</template>

<script setup lang="ts">
defineEmits<{
    'open-devices': [];
    'open-floors': [];
    'open-energy': [];
    'open-climate': [];
}>();
</script>

<style scoped src="./QuickActions.css"></style>