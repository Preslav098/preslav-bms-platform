<template>
    <button ref="markerElement" class="floor-marker" :class="[
        `floor-marker--${device.status}`,
        {
            'floor-marker--dragging': dragging,
            'floor-marker--editable': editable
        }
    ]" type="button" :style="markerStyle" :title="device.name" @pointerdown="handlePointerDown"
        @click="handleClick">
        <span class="floor-marker__pulse"></span>

        <span class="floor-marker__icon">
            {{ markerIcon }}
        </span>

        <span class="floor-marker__label">
            {{ device.name }}
        </span>
    </button>
</template>

<script setup lang="ts">
import {
    computed,
    ref
} from 'vue';

import type {
    CSSProperties
} from 'vue';
import type { Device } from '../../models/Device';

const props = withDefaults(
    defineProps<{
        device: Device;
        x: number;
        y: number;
        editable?: boolean;
    }>(),
    {
        editable: false
    }
);

const emit = defineEmits<{
    select: [device: Device];
    move: [
        payload: {
            device: Device;
            x: number;
            y: number;
        }
    ];
}>();

const markerElement = ref<HTMLButtonElement | null>(null);
const dragging = ref(false);
const movedDuringDrag = ref(false);

const markerStyle = computed<CSSProperties>(() => ({
    left: `${normalizeCoordinate(props.x)}%`,
    top: `${normalizeCoordinate(props.y)}%`
}));

const markerIcon = computed(() => {
    const searchableText = [
        props.device.name,
        props.device.model
    ]
        .join(' ')
        .toLowerCase();

    if (
        searchableText.includes('door') ||
        searchableText.includes('window')
    ) {
        return '🚪';
    }

    if (
        searchableText.includes('h&t') ||
        searchableText.includes('temperature') ||
        searchableText.includes('humidity') ||
        searchableText.includes('climate')
    ) {
        return '🌡';
    }

    if (
        searchableText.includes('plug') ||
        searchableText.includes('power') ||
        searchableText.includes('pm') ||
        searchableText.includes('em')
    ) {
        return '⚡';
    }

    return '◉';
});

function handlePointerDown(event: PointerEvent): void {
    if (!props.editable) {
        return;
    }

    const marker = markerElement.value;
    const surface = marker?.offsetParent as HTMLElement | null;

    if (!marker || !surface) {
        return;
    }

    event.preventDefault();

    dragging.value = true;
    movedDuringDrag.value = false;

    marker.setPointerCapture(event.pointerId);

    const handlePointerMove = (moveEvent: PointerEvent): void => {
        const bounds = surface.getBoundingClientRect();

        if (
            bounds.width <= 0 ||
            bounds.height <= 0
        ) {
            return;
        }

        movedDuringDrag.value = true;

        const x =
            ((moveEvent.clientX - bounds.left) / bounds.width) * 100;
        const y =
            ((moveEvent.clientY - bounds.top) / bounds.height) * 100;

        emit('move', {
            device: props.device,
            x: normalizeCoordinate(x),
            y: normalizeCoordinate(y)
        });
    };

    const handlePointerUp = (): void => {
        dragging.value = false;

        marker.removeEventListener(
            'pointermove',
            handlePointerMove
        );

        marker.removeEventListener(
            'pointerup',
            handlePointerUp
        );

        marker.removeEventListener(
            'pointercancel',
            handlePointerUp
        );
    };

    marker.addEventListener(
        'pointermove',
        handlePointerMove
    );

    marker.addEventListener(
        'pointerup',
        handlePointerUp
    );

    marker.addEventListener(
        'pointercancel',
        handlePointerUp
    );
}

function handleClick(): void {
    if (movedDuringDrag.value) {
        movedDuringDrag.value = false;
        return;
    }

    emit('select', props.device);
}

function normalizeCoordinate(value: number): number {
    if (!Number.isFinite(value)) {
        return 50;
    }

    return Math.min(100, Math.max(0, value));
}
</script>

<style scoped src="./FloorMarker.css"></style>