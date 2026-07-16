<template>
    <section class="dashboard-stats">
        <article class="dashboard-stats__card">
            <span class="dashboard-stats__icon">📡</span>

            <div>
                <span class="dashboard-stats__label">
                    Total devices
                </span>

                <strong>{{ totalDevices }}</strong>

                <small>Registered infrastructure</small>
            </div>
        </article>

        <article class="dashboard-stats__card">
            <span class="dashboard-stats__icon dashboard-stats__icon--success">
                ✓
            </span>

            <div>
                <span class="dashboard-stats__label">
                    Online devices
                </span>

                <strong class="dashboard-stats__value--success">
                    {{ onlineDevices }}
                </strong>

                <small>Currently connected</small>
            </div>
        </article>

        <article class="dashboard-stats__card">
            <span class="dashboard-stats__icon dashboard-stats__icon--danger">
                !
            </span>

            <div>
                <span class="dashboard-stats__label">
                    Offline devices
                </span>

                <strong :class="{
                    'dashboard-stats__value--danger':
                        offlineDevices > 0
                }">
                    {{ offlineDevices }}
                </strong>

                <small>Require attention</small>
            </div>
        </article>

        <article class="dashboard-stats__card">
            <span class="dashboard-stats__icon">🏢</span>

            <div>
                <span class="dashboard-stats__label">
                    Floors
                </span>

                <strong>{{ totalGroups }}</strong>

                <small>Configured groups</small>
            </div>
        </article>
    </section>
</template>

<script setup lang="ts">
defineProps<{
    totalDevices: number;
    onlineDevices: number;
    offlineDevices: number;
    totalGroups: number;
}>();
</script>

<style scoped src="./DashboardStats.css"></style>