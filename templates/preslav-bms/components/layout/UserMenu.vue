<template>
    <div class="user-menu">
        <div class="user-menu__header">
            <div class="user-menu__avatar">
                {{ initials }}
            </div>

            <div>
                <strong>{{ userName }}</strong>
                <small>Facility Manager</small>
            </div>
        </div>

        <div class="user-menu__divider"></div>

        <button class="user-menu__item" type="button" @click="$emit('profile')">
            <span>👤</span>
            <span>Profile</span>
        </button>


        <div class="user-menu__divider"></div>

        <button class="user-menu__item user-menu__item--danger" type="button" @click="$emit('logout')">
            <span>↪</span>
            <span>Logout</span>
        </button>
    </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
    userName: string;
}>();

defineEmits<{
    profile: [];
    logout: [];
}>();

const initials = computed(() => {
    const parts = props.userName
        .trim()
        .split(/\s+/)
        .filter(Boolean);

    if (parts.length === 0) {
        return 'FM';
    }

    if (parts.length === 1) {
        return parts[0].slice(0, 2).toUpperCase();
    }

    return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase();
});
</script>

<style scoped src="./UserMenu.css"></style>