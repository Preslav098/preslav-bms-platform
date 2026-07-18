<template>
    <Teleport to="body">
        <Transition name="device-management">
            <div
                v-if="open"
                class="device-management"
                @click.self="$emit('close')"
            >
                <section
                    class="device-management__dialog"
                    role="dialog"
                    aria-modal="true"
                    aria-labelledby="device-management-title"
                >
                    <header class="device-management__header">
                        <div>
                            <p>Fleet onboarding</p>
                            <h2 id="device-management-title">Add Shelly devices</h2>
                            <span>
                                Devices connect to Fleet Manager first and then appear here for approval.
                            </span>
                        </div>

                        <button
                            class="device-management__close"
                            type="button"
                            aria-label="Close device management"
                            @click="$emit('close')"
                        >
                            ×
                        </button>
                    </header>

                    <div class="device-management__guidance">
                        <span aria-hidden="true">＋</span>
                        <div>
                            <strong>How device onboarding works</strong>
                            <p>
                                Configure the Fleet Manager WebSocket on a Wi-Fi Shelly device. New devices enter the waiting room; approve them below. BLU sensors arrive through their gateway device.
                            </p>
                        </div>
                    </div>

                    <div class="device-management__toolbar">
                        <div>
                            <strong>{{ pendingDevices.length }}</strong>
                            <span>{{ pendingDevices.length === 1 ? 'device waiting' : 'devices waiting' }}</span>
                        </div>

                        <button
                            type="button"
                            :disabled="loading || busyEntryId !== null"
                            @click="$emit('refresh')"
                        >
                            <span :class="{'device-management__spin': loading}" aria-hidden="true">↻</span>
                            Refresh waiting room
                        </button>
                    </div>

                    <div v-if="error" class="device-management__message device-management__message--error">
                        {{ error }}
                    </div>

                    <div v-else-if="loading" class="device-management__message">
                        Loading devices waiting for approval…
                    </div>

                    <div v-else-if="pendingDevices.length === 0" class="device-management__empty">
                        <span aria-hidden="true">✓</span>
                        <h3>No devices are waiting</h3>
                        <p>
                            Connect a Shelly device to this Fleet Manager instance, then refresh this list.
                        </p>
                    </div>

                    <div v-else class="device-management__list">
                        <article
                            v-for="device in pendingDevices"
                            :key="device.entryId"
                            class="device-management__card"
                        >
                            <div class="device-management__identity">
                                <span class="device-management__icon" aria-hidden="true">
                                    {{ device.icon }}
                                </span>

                                <div>
                                    <h3>{{ device.name }}</h3>
                                    <p>{{ device.model }}</p>
                                </div>
                            </div>

                            <dl>
                                <div>
                                    <dt>Shelly ID</dt>
                                    <dd>{{ device.shellyID }}</dd>
                                </div>
                                <div>
                                    <dt>Connection</dt>
                                    <dd>{{ device.connection }}</dd>
                                </div>
                                <div>
                                    <dt>IP address</dt>
                                    <dd>{{ device.ip }}</dd>
                                </div>
                                <div>
                                    <dt>Last seen</dt>
                                    <dd>{{ device.lastSeen }}</dd>
                                </div>
                            </dl>

                            <footer>
                                <button
                                    class="device-management__reject"
                                    type="button"
                                    :disabled="busyEntryId !== null"
                                    @click="$emit('reject', device)"
                                >
                                    Reject
                                </button>

                                <button
                                    class="device-management__approve"
                                    type="button"
                                    :disabled="busyEntryId !== null"
                                    @click="$emit('approve', device)"
                                >
                                    <span v-if="busyEntryId === device.entryId" class="device-management__spin" aria-hidden="true">↻</span>
                                    {{ busyEntryId === device.entryId ? 'Adding…' : 'Add to BMS' }}
                                </button>
                            </footer>
                        </article>
                    </div>
                </section>
            </div>
        </Transition>
    </Teleport>
</template>

<script setup lang="ts">
export interface PendingBmsDevice {
    entryId: string;
    shellyID: string;
    profileId?: string;
    name: string;
    model: string;
    connection: string;
    ip: string;
    lastSeen: string;
    icon: string;
}

defineProps<{
    open: boolean;
    pendingDevices: PendingBmsDevice[];
    loading: boolean;
    error: string | null;
    busyEntryId: string | null;
}>();

defineEmits<{
    close: [];
    refresh: [];
    approve: [device: PendingBmsDevice];
    reject: [device: PendingBmsDevice];
}>();
</script>

<style scoped src="./DeviceEnrollmentModal.css"></style>
