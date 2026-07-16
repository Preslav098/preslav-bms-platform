<template>
    <section class="floor-canvas">
        <header class="floor-canvas__toolbar">
            <div>
                <strong>Interactive floor plan</strong>
                <span>
                    {{ placedDevices.length }} placed ·
                    {{ unplacedDevices.length }} unplaced
                </span>
            </div>

            <div class="floor-canvas__toolbar-actions">
                <button
                    class="floor-canvas__edit-button"
                    type="button"
                    :disabled="!imageUrl"
                    :class="{
                        'floor-canvas__edit-button--active': editMode
                    }"
                    @click="editMode = !editMode"
                >
                    {{ editMode ? 'Finish editing' : 'Edit positions' }}
                </button>

                <div class="floor-canvas__zoom-controls">
                    <button type="button" aria-label="Zoom out" @click="zoomOut">−</button>
                    <span>{{ zoomPercentage }}%</span>
                    <button type="button" aria-label="Zoom in" @click="zoomIn">+</button>
                    <button type="button" @click="resetZoom">Reset</button>
                </div>
            </div>
        </header>

        <div v-if="editMode" class="floor-canvas__edit-banner">
            Drag unplaced devices onto the plan or move existing markers.
            Positions are saved automatically in this browser.
        </div>

        <div class="floor-canvas__workspace">
            <div class="floor-canvas__viewport">
                <div
                    ref="surfaceElement"
                    class="floor-canvas__surface"
                    :class="{
                        'floor-canvas__surface--drop-active': dragOver
                    }"
                    :style="surfaceStyle"
                    @dragover.prevent="handleDragOver"
                    @dragleave="dragOver = false"
                    @drop.prevent="handleDrop"
                >
                    <img
                        v-if="imageUrl"
                        class="floor-canvas__image"
                        :src="imageUrl"
                        :alt="altText"
                        draggable="false"
                    />

                    <div v-else class="floor-canvas__placeholder">
                        <span>🗺️</span>
                        <h4>No floor plan uploaded</h4>
                        <p>
                            Upload a floor-plan image before positioning devices.
                        </p>
                    </div>

                    <template v-if="imageUrl">
                        <FloorMarker
                            v-for="device in placedDevices"
                            :key="String(device.id)"
                            :device="device"
                            :x="getDevicePosition(device).x"
                            :y="getDevicePosition(device).y"
                            :editable="editMode"
                            @select="$emit('select-device', $event)"
                            @move="handleDeviceMove"
                        />
                    </template>

                    <div
                        v-if="imageUrl && placedDevices.length === 0"
                        class="floor-canvas__drop-hint"
                    >
                        <span>＋</span>
                        <strong>Drop devices here</strong>
                        <small>Enable editing and drag a device from the panel.</small>
                    </div>
                </div>
            </div>

            <aside class="floor-canvas__device-tray">
                <header>
                    <div>
                        <p>Device placement</p>
                        <h4>Unplaced devices</h4>
                    </div>
                    <span>{{ unplacedDevices.length }}</span>
                </header>

                <div v-if="!imageUrl" class="floor-canvas__tray-empty">
                    Upload a plan to enable device placement.
                </div>

                <div v-else-if="unplacedDevices.length === 0" class="floor-canvas__tray-empty">
                    <strong>All devices placed</strong>
                    <span>Every device assigned to this floor is visible on the plan.</span>
                </div>

                <div v-else class="floor-canvas__tray-list">
                    <button
                        v-for="device in unplacedDevices"
                        :key="String(device.id)"
                        class="floor-canvas__tray-device"
                        type="button"
                        :draggable="editMode"
                        :disabled="!editMode"
                        @dragstart="handleDragStart($event, device)"
                        @click="placeDeviceAutomatically(device)"
                    >
                        <span class="floor-canvas__tray-icon" aria-hidden="true">
                            {{ getDeviceIcon(device) }}
                        </span>

                        <span class="floor-canvas__tray-info">
                            <strong>{{ device.name }}</strong>
                            <small>{{ device.model }}</small>
                        </span>

                        <span
                            class="floor-canvas__tray-status"
                            :class="`floor-canvas__tray-status--${device.status}`"
                        ></span>
                    </button>
                </div>

                <p v-if="imageUrl && !editMode" class="floor-canvas__tray-help">
                    Select “Edit positions” to place or move devices.
                </p>
            </aside>
        </div>

        <footer class="floor-canvas__legend">
            <span><i class="floor-canvas__legend-dot floor-canvas__legend-dot--online"></i>Online</span>
            <span><i class="floor-canvas__legend-dot floor-canvas__legend-dot--offline"></i>Offline</span>
            <span><i class="floor-canvas__legend-dot floor-canvas__legend-dot--warning"></i>Warning / attention</span>
            <span>Click a marker to open device details.</span>
        </footer>
    </section>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import type { CSSProperties } from 'vue';

import FloorMarker from './FloorMarker.vue';
import { useFloorDevicePositions } from '../../composables/useFloorDevicePositions';
import type { FloorDevicePosition } from '../../composables/useFloorDevicePositions';
import type { Device } from '../../models/Device';

const props = defineProps<{
    floorId: string | number;
    imageUrl: string | null;
    altText: string;
    devices: Device[];
}>();

defineEmits<{
    'select-device': [device: Device];
}>();

const {
    positions,
    getPosition,
    savePosition
} = useFloorDevicePositions();

const zoom = ref(1);
const editMode = ref(false);
const dragOver = ref(false);
const surfaceElement = ref<HTMLElement | null>(null);

const zoomPercentage = computed(() => Math.round(zoom.value * 100));

const surfaceStyle = computed<CSSProperties>(() => ({
    transform: `scale(${zoom.value})`
}));

const placedDevices = computed(() => {
    void positions.value;

    return props.devices.filter((device) => {
        return Boolean(
            getPosition(props.floorId, device.id) ||
            (
                typeof device.floorX === 'number' &&
                typeof device.floorY === 'number'
            )
        );
    });
});

const unplacedDevices = computed(() => {
    const placedIds = new Set(
        placedDevices.value.map((device) => String(device.id))
    );

    return props.devices.filter(
        (device) => !placedIds.has(String(device.id))
    );
});

function getDevicePosition(device: Device): FloorDevicePosition {
    const storedPosition = getPosition(props.floorId, device.id);

    if (storedPosition) {
        return storedPosition;
    }

    return {
        x: typeof device.floorX === 'number' ? device.floorX : 50,
        y: typeof device.floorY === 'number' ? device.floorY : 50
    };
}

function handleDeviceMove(payload: {
    device: Device;
    x: number;
    y: number;
}): void {
    savePosition(props.floorId, payload.device.id, {
        x: payload.x,
        y: payload.y
    });
}

function handleDragStart(event: DragEvent, device: Device): void {
    if (!editMode.value || !event.dataTransfer) {
        event.preventDefault();
        return;
    }

    event.dataTransfer.effectAllowed = 'move';
    event.dataTransfer.setData('text/plain', String(device.id));
}

function handleDragOver(event: DragEvent): void {
    if (!editMode.value || !props.imageUrl) {
        return;
    }

    dragOver.value = true;

    if (event.dataTransfer) {
        event.dataTransfer.dropEffect = 'move';
    }
}

function handleDrop(event: DragEvent): void {
    dragOver.value = false;

    if (!editMode.value || !props.imageUrl) {
        return;
    }

    const deviceId = event.dataTransfer?.getData('text/plain');
    const device = props.devices.find(
        (candidate) => String(candidate.id) === deviceId
    );
    const surface = surfaceElement.value;

    if (!device || !surface) {
        return;
    }

    const bounds = surface.getBoundingClientRect();

    if (bounds.width <= 0 || bounds.height <= 0) {
        return;
    }

    savePosition(props.floorId, device.id, {
        x: normalizeCoordinate(
            ((event.clientX - bounds.left) / bounds.width) * 100
        ),
        y: normalizeCoordinate(
            ((event.clientY - bounds.top) / bounds.height) * 100
        )
    });
}

function placeDeviceAutomatically(device: Device): void {
    if (!editMode.value || !props.imageUrl) {
        return;
    }

    const index = placedDevices.value.length;
    const columns = 4;

    savePosition(props.floorId, device.id, {
        x: Math.min(88, 15 + (index % columns) * 23),
        y: Math.min(88, 18 + Math.floor(index / columns) * 20)
    });
}

function getDeviceIcon(device: Device): string {
    const value = `${device.name} ${device.model}`.toLowerCase();

    if (value.includes('door') || value.includes('window')) {
        return '🚪';
    }

    if (
        value.includes('h&t') ||
        value.includes('temperature') ||
        value.includes('humidity')
    ) {
        return '🌡';
    }

    if (
        value.includes('plug') ||
        value.includes('power') ||
        value.includes('pm') ||
        value.includes('em')
    ) {
        return '⚡';
    }

    return '◉';
}

function normalizeCoordinate(value: number): number {
    if (!Number.isFinite(value)) {
        return 50;
    }

    return Math.min(97, Math.max(3, value));
}

function zoomIn(): void {
    zoom.value = Math.min(2, Number((zoom.value + 0.1).toFixed(1)));
}

function zoomOut(): void {
    zoom.value = Math.max(0.5, Number((zoom.value - 0.1).toFixed(1)));
}

function resetZoom(): void {
    zoom.value = 1;
}
</script>

<style scoped src="./FloorCanvas.css"></style>
