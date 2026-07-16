<template>
    <section class="door-page">
        <header class="door-page__header">
            <div>
                <p class="door-page__eyebrow">
                    Access monitoring
                </p>

                <h2>Door &amp; Window Monitoring</h2>

                <p class="door-page__description">
                    Live opening state and locally recorded 24-hour activity
                    from Fleet Manager updates.
                </p>
            </div>

            <button class="door-page__refresh" type="button" :disabled="isRefreshing" @click="handleRefresh">
                <span :class="{
                    'door-page__refresh-icon--spinning': isRefreshing
                }">
                    ↻
                </span>

                {{ isRefreshing ? 'Refreshing…' : 'Refresh data' }}
            </button>
        </header>

        <div v-if="!doorDevice" class="door-page__empty">
            <div class="door-page__empty-icon">
                🚪
            </div>

            <h3>No door/window sensor found</h3>

            <p>
                Connect a Shelly BLU Door/Window sensor and wait for Fleet
                Manager to publish its readings.
            </p>
        </div>

        <template v-else>
            <section v-if="liveReading.open === true" class="door-page__warning">
                <div class="door-page__warning-icon">
                    !
                </div>

                <div>
                    <strong>
                        Door or window is currently open
                    </strong>

                    <p>
                        Check whether the opening is expected and secure the
                        monitored area when necessary.
                    </p>
                </div>
            </section>

            <section class="door-page__summary">
                <article class="door-page__summary-card door-page__summary-card--state" :class="{
                    'door-page__summary-card--open':
                        liveReading.open === true,
                    'door-page__summary-card--closed':
                        liveReading.open === false
                }">
                    <div class="door-page__summary-icon">
                        {{ liveReading.open === true ? '🚪' : '🔒' }}
                    </div>

                    <div>
                        <span>Current state</span>

                        <strong>
                            {{ stateLabel }}
                        </strong>

                        <small>
                            Live BTHome reading
                        </small>
                    </div>
                </article>

                <article class="door-page__summary-card">
                    <div class="door-page__summary-icon">
                        ↗
                    </div>

                    <div>
                        <span>Open events — 24H</span>

                        <strong>
                            {{ openEventCount }}
                        </strong>

                        <small>
                            Observed state transitions
                        </small>
                    </div>
                </article>

                <article class="door-page__summary-card">
                    <div class="door-page__summary-icon">
                        🔋
                    </div>

                    <div>
                        <span>Battery</span>

                        <strong>
                            {{ formatBattery(liveReading.battery) }}
                        </strong>

                        <small>
                            {{ batteryStatus }}
                        </small>
                    </div>
                </article>

                <article class="door-page__summary-card">
                    <div class="door-page__summary-icon">
                        ◉
                    </div>

                    <div>
                        <span>Sensor status</span>

                        <strong :class="{
                            'door-page__online': liveReading.online,
                            'door-page__offline': !liveReading.online
                        }">
                            {{ liveReading.online ? 'Online' : 'Offline' }}
                        </strong>

                        <small>
                            {{
                                liveReading.rssi !== null
                                    ? `${liveReading.rssi} dBm`
                                    : 'Signal unavailable'
                            }}
                        </small>
                    </div>
                </article>
            </section>

            <div class="door-page__content-grid">
                <article class="door-page__timeline">
                    <header class="door-page__panel-header">
                        <div>
                            <p>Access history</p>
                            <h3>Last 24 hours</h3>

                            <small class="door-page__timeline-note">
                                Live events recorded locally while this BMS is running
                            </small>
                        </div>

                        <span>
                            {{ doorEvents.length }}
                            {{ doorEvents.length === 1 ? 'event' : 'events' }}
                        </span>
                    </header>

                    <div v-if="doorEvents.length === 0" class="door-page__message">
                        No door state changes have been observed by this
                        browser during the last 24 hours.
                    </div>

                    <div v-else class="door-page__timeline-list">
                        <article v-for="event in doorEvents" :key="event.key" class="door-page__timeline-event">
                            <div class="door-page__timeline-marker" :class="{
                                'door-page__timeline-marker--open':
                                    event.state === 'open',
                                'door-page__timeline-marker--closed':
                                    event.state === 'closed'
                            }">
                                {{ event.state === 'open' ? '↗' : '✓' }}
                            </div>

                            <div class="door-page__timeline-content">
                                <div>
                                    <strong>
                                        {{
                                            event.state === 'open'
                                                ? 'Opening detected'
                                                : 'Opening secured'
                                        }}
                                    </strong>

                                    <span :class="{
                                        'door-page__event-badge--open':
                                            event.state === 'open',
                                        'door-page__event-badge--closed':
                                            event.state === 'closed'
                                    }">
                                        {{
                                            event.state === 'open'
                                                ? 'Open'
                                                : 'Closed'
                                        }}
                                    </span>
                                </div>

                                <p>
                                    {{
                                        event.state === 'open'
                                            ? 'The door/window sensor reported an open state.'
                                            : 'The door/window sensor returned to its closed state.'
                                    }}
                                </p>

                                <small>
                                    {{ formatEventTime(event.timestamp) }}
                                </small>
                            </div>
                        </article>
                    </div>
                </article>

                <article class="door-page__insights">
                    <header class="door-page__panel-header">
                        <div>
                            <p>Security insights</p>
                            <h3>Opening activity</h3>
                        </div>

                        <span :class="{
                            'door-page__security-badge--secure':
                                liveReading.open === false,
                            'door-page__security-badge--open':
                                liveReading.open === true,
                            'door-page__security-badge--unknown':
                                liveReading.open === null
                        }">
                            {{ securityLabel }}
                        </span>
                    </header>

                    <div class="door-page__state-visual">
                        <div class="door-page__door-visual" :class="{
                            'door-page__door-visual--open':
                                liveReading.open === true
                        }">
                            <div class="door-page__door-panel">
                                <span></span>
                            </div>

                            <div class="door-page__door-frame"></div>
                        </div>

                        <strong>
                            {{ stateLabel }}
                        </strong>

                        <span>
                            Current monitored state
                        </span>
                    </div>

                    <div class="door-page__insight-list">
                        <div>
                            <span>Last state change</span>

                            <strong>
                                {{ lastEventLabel }}
                            </strong>
                        </div>

                        <div>
                            <span>Open events</span>

                            <strong>
                                {{ openEventCount }}
                            </strong>
                        </div>

                        <div>
                            <span>Close events</span>

                            <strong>
                                {{ closeEventCount }}
                            </strong>
                        </div>

                        <div>
                            <span>Battery condition</span>

                            <strong>
                                {{ batteryStatus }}
                            </strong>
                        </div>

                        <div>
                            <span>Last sensor update</span>

                            <strong>
                                {{ formattedLastSeen }}
                            </strong>
                        </div>
                    </div>
                </article>
            </div>

            <section class="door-page__devices">
                <header class="door-page__section-header">
                    <div>
                        <p>Access sensors</p>
                        <h3>Door/window devices</h3>
                    </div>

                    <span>1 detected</span>
                </header>

                <article class="door-page__device-card">
                    <div class="door-page__device-icon">
                        🚪
                    </div>

                    <div class="door-page__device-main">
                        <div class="door-page__device-heading">
                            <div>
                                <h4>
                                    {{
                                        doorDevice.name ??
                                        'Shelly BLU Door/Window'
                                    }}
                                </h4>

                                <p>
                                    {{
                                        doorDevice.type ??
                                        'Opening sensor'
                                    }}
                                </p>
                            </div>

                            <span :class="{
                                'door-page__device-status--online':
                                    liveReading.online,
                                'door-page__device-status--offline':
                                    !liveReading.online
                            }">
                                {{
                                    liveReading.online
                                        ? 'Online'
                                        : 'Offline'
                                }}
                            </span>
                        </div>

                        <div class="door-page__device-readings">
                            <div>
                                <span>State</span>
                                <strong>{{ stateLabel }}</strong>
                            </div>

                            <div>
                                <span>Battery</span>

                                <strong>
                                    {{ formatBattery(liveReading.battery) }}
                                </strong>
                            </div>

                            <div>
                                <span>Signal</span>

                                <strong>
                                    {{
                                        liveReading.rssi !== null
                                            ? `${liveReading.rssi} dBm`
                                            : 'No data'
                                    }}
                                </strong>
                            </div>

                            <div>
                                <span>Events — 24H</span>

                                <strong>
                                    {{ doorEvents.length }}
                                </strong>
                            </div>
                        </div>

                        <div class="door-page__device-footer">
                            <span>
                                ID: {{ doorDevice.shellyID }}
                            </span>

                            <span>
                                {{ formattedLastSeen }}
                            </span>
                        </div>
                    </div>
                </article>
            </section>
        </template>
    </section>
</template>

<script setup lang="ts">
import {
    computed,
    onMounted,
    ref,
    watch
} from 'vue';

import type { HostDevice } from '@host/index';

import {
    extractBluDoor,
    isBluDoorDevice
} from '../../utils/bthome';

type DoorState = 'open' | 'closed';

interface StoredDoorEvent {
    timestamp: string;
    state: DoorState;
}

interface DoorHistoryEvent {
    key: string;
    timestamp: string;
    state: DoorState;
    previous: DoorState | null;
    next: DoorState;
    source: 'live';
}

const props = withDefaults(
    defineProps<{
        devices: HostDevice[];
        refreshing?: boolean;
    }>(),
    {
        refreshing: false
    }
);

const emit = defineEmits<{
    refresh: [];
}>();

const DAY_MS = 24 * 60 * 60 * 1000;

const DOOR_HISTORY_STORAGE_PREFIX =
    'preslav-bms:door-history:';

const localRefreshing = ref(false);
const doorEvents = ref<DoorHistoryEvent[]>([]);
const previousLiveState = ref<DoorState | null>(null);

const doorDevice = computed(() => {
    return props.devices.find(isBluDoorDevice);
});

const liveReading = computed(() => {
    if (!doorDevice.value) {
        return {
            open: null,
            state: 'unknown' as const,
            battery: null,
            rssi: null,
            lastSeen: null,
            online: false
        };
    }

    return extractBluDoor(doorDevice.value);
});

const isRefreshing = computed(() => {
    return (
        props.refreshing ||
        localRefreshing.value
    );
});

const stateLabel = computed(() => {
    if (liveReading.value.open === true) {
        return 'Open';
    }

    if (liveReading.value.open === false) {
        return 'Closed';
    }

    return 'Unknown';
});

const securityLabel = computed(() => {
    if (liveReading.value.open === true) {
        return 'Opening detected';
    }

    if (liveReading.value.open === false) {
        return 'Secured';
    }

    return 'Unknown';
});

const openEventCount = computed(() => {
    return doorEvents.value.filter((event) => {
        return event.state === 'open';
    }).length;
});

const closeEventCount = computed(() => {
    return doorEvents.value.filter((event) => {
        return event.state === 'closed';
    }).length;
});

const lastEventLabel = computed(() => {
    const event = doorEvents.value[0];

    if (!event) {
        return 'No recent event';
    }

    return (
        `${event.state === 'open' ? 'Opened' : 'Closed'} ` +
        formatRelativeTime(event.timestamp)
    );
});

const batteryStatus = computed(() => {
    const battery = liveReading.value.battery;

    if (battery === null) {
        return 'No data';
    }

    if (battery < 20) {
        return 'Replace soon';
    }

    if (battery < 50) {
        return 'Battery moderate';
    }

    return 'Battery healthy';
});

const formattedLastSeen = computed(() => {
    const lastSeen = liveReading.value.lastSeen;

    if (!lastSeen) {
        return 'Last seen unknown';
    }

    return formatRelativeTime(
        lastSeen,
        true
    );
});

function getStorageKey(): string | null {
    const device = doorDevice.value;

    if (!device) {
        return null;
    }

    return (
        `${DOOR_HISTORY_STORAGE_PREFIX}` +
        `${device.shellyID}`
    );
}

function readStoredHistory(): DoorHistoryEvent[] {
    const storageKey = getStorageKey();

    if (
        !storageKey ||
        typeof localStorage === 'undefined'
    ) {
        return [];
    }

    try {
        const raw = localStorage.getItem(storageKey);

        if (!raw) {
            return [];
        }

        const parsed = JSON.parse(
            raw
        ) as StoredDoorEvent[];

        if (!Array.isArray(parsed)) {
            return [];
        }

        const cutoff = Date.now() - DAY_MS;

        const validEvents = parsed
            .filter((event) => {
                const timestamp =
                    new Date(event.timestamp).getTime();

                return (
                    typeof event.timestamp === 'string' &&
                    (
                        event.state === 'open' ||
                        event.state === 'closed'
                    ) &&
                    Number.isFinite(timestamp) &&
                    timestamp >= cutoff
                );
            })
            .sort((first, second) => {
                return (
                    new Date(second.timestamp).getTime() -
                    new Date(first.timestamp).getTime()
                );
            });

        return validEvents.map(
            (event, index, events) => {
                const olderEvent = events[index + 1];

                return {
                    key:
                        `${event.timestamp}-${event.state}-${index}`,
                    timestamp: event.timestamp,
                    state: event.state,
                    previous:
                        olderEvent?.state ?? null,
                    next: event.state,
                    source: 'live' as const
                };
            }
        );
    } catch {
        return [];
    }
}

function persistHistory(): void {
    const storageKey = getStorageKey();

    if (
        !storageKey ||
        typeof localStorage === 'undefined'
    ) {
        return;
    }

    const cutoff = Date.now() - DAY_MS;

    const storedEvents: StoredDoorEvent[] =
        doorEvents.value
            .filter((event) => {
                return (
                    new Date(event.timestamp).getTime() >=
                    cutoff
                );
            })
            .map((event) => ({
                timestamp: event.timestamp,
                state: event.state
            }));

    localStorage.setItem(
        storageKey,
        JSON.stringify(storedEvents)
    );
}

function addLiveEvent(
    state: DoorState,
    previous: DoorState | null
): void {
    const timestamp = new Date().toISOString();

    const newEvent: DoorHistoryEvent = {
        key: `${timestamp}-${state}`,
        timestamp,
        state,
        previous,
        next: state,
        source: 'live'
    };

    const cutoff = Date.now() - DAY_MS;

    doorEvents.value = [
        newEvent,
        ...doorEvents.value
    ].filter((event) => {
        return (
            new Date(event.timestamp).getTime() >=
            cutoff
        );
    });

    persistHistory();
}

function loadStoredHistory(): void {
    doorEvents.value = readStoredHistory();

    const state = liveReading.value.state;

    previousLiveState.value =
        state === 'open' || state === 'closed'
            ? state
            : null;
}

function formatBattery(
    value: number | null
): string {
    return value === null
        ? 'No data'
        : `${value.toFixed(0)}%`;
}

function formatEventTime(
    timestamp: string
): string {
    return new Date(timestamp).toLocaleString();
}

function formatRelativeTime(
    timestamp: string,
    includeUpdated = false
): string {
    const date = new Date(timestamp);
    const difference = Math.max(
        Date.now() - date.getTime(),
        0
    );

    if (difference < 60_000) {
        return includeUpdated
            ? 'Updated just now'
            : 'just now';
    }

    if (difference < 60 * 60_000) {
        const minutes = Math.floor(
            difference / 60_000
        );

        return includeUpdated
            ? `Updated ${minutes} min ago`
            : `${minutes} min ago`;
    }

    if (difference < DAY_MS) {
        const hours = Math.floor(
            difference / (60 * 60_000)
        );

        return includeUpdated
            ? `Updated ${hours} h ago`
            : `${hours} h ago`;
    }

    return date.toLocaleString();
}

async function handleRefresh(): Promise<void> {
    if (localRefreshing.value) {
        return;
    }

    localRefreshing.value = true;

    try {
        emit('refresh');

        doorEvents.value =
            readStoredHistory();
    } finally {
        localRefreshing.value = false;
    }
}

watch(
    () => liveReading.value.state,
    (nextState) => {
        if (
            nextState !== 'open' &&
            nextState !== 'closed'
        ) {
            return;
        }

        const previousState =
            previousLiveState.value;

        if (previousState === null) {
            previousLiveState.value =
                nextState;

            return;
        }

        if (previousState === nextState) {
            return;
        }

        addLiveEvent(
            nextState,
            previousState
        );

        previousLiveState.value =
            nextState;
    }
);

watch(
    () => doorDevice.value?.shellyID,
    () => {
        loadStoredHistory();
    }
);

onMounted(() => {
    loadStoredHistory();
});
</script>

<style scoped src="./DoorPage.css"></style>