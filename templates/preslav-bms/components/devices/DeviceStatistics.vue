<template>
    <section class="device-statistics" aria-label="Device statistics">
        <article class="device-statistics__card">
            <span class="device-statistics__icon">📡</span>

            <div>
                <span>Total devices</span>
                <strong>{{ total }}</strong>
            </div>
        </article>

        <article class="device-statistics__card">
            <span class="
                    device-statistics__icon
                    device-statistics__icon--online
                ">
                ✓
            </span>

            <div>
                <span>Online</span>
                <strong class="device-statistics__value--online">
                    {{ online }}
                </strong>
            </div>
        </article>

        <article class="device-statistics__card">
            <span class="
                    device-statistics__icon
                    device-statistics__icon--offline
                ">
                ×
            </span>

            <div>
                <span>Offline</span>
                <strong :class="{
                    'device-statistics__value--offline':
                        offline > 0
                }">
                    {{ offline }}
                </strong>
            </div>
        </article>

        <article class="device-statistics__card">
            <span class="
                    device-statistics__icon
                    device-statistics__icon--warning
                ">
                !
            </span>

            <div>
                <span>Warning</span>
                <strong :class="{
                    'device-statistics__value--warning':
                        warning > 0
                }">
                    {{ warning }}
                </strong>
            </div>
        </article>
    </section>
</template>

<script setup lang="ts">
defineProps<{
    total: number;
    online: number;
    offline: number;
    warning: number;
}>();
</script>

<style scoped src="./DeviceStatistics.css"></style>