<template>
    <section class="floor-plan-uploader">
        <input ref="fileInput" class="floor-plan-uploader__input" type="file"
            accept="image/png,image/jpeg,image/webp,image/svg+xml" @change="handleFileSelection" />

        <button class="floor-plan-uploader__button" type="button" @click="fileInput?.click()">
            {{ hasPlan ? 'Replace floor plan' : 'Upload floor plan' }}
        </button>

        <button v-if="hasPlan" class="floor-plan-uploader__remove" type="button" @click="$emit('remove')">
            Remove
        </button>
    </section>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';

const props = defineProps<{
    imageUrl: string | null;
}>();

const emit = defineEmits<{
    upload: [
        payload: {
            imageUrl: string;
            fileName: string;
        }
    ];
    remove: [];
}>();

const fileInput = ref<HTMLInputElement | null>(null);

const hasPlan = computed(() => {
    return Boolean(props.imageUrl);
});

function handleFileSelection(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];

    if (!file) {
        return;
    }

    const allowedTypes = [
        'image/png',
        'image/jpeg',
        'image/webp',
        'image/svg+xml'
    ];

    if (!allowedTypes.includes(file.type)) {
        input.value = '';
        return;
    }

    const reader = new FileReader();

    reader.addEventListener('load', () => {
        if (typeof reader.result !== 'string') {
            return;
        }

        emit('upload', {
            imageUrl: reader.result,
            fileName: file.name
        });

        input.value = '';
    });

    reader.readAsDataURL(file);
}
</script>

<style scoped src="./FloorPlanUploader.css"></style>