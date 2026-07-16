<template>
    <header class="topbar">
        <button class="topbar__mobile-menu" type="button" aria-label="Open navigation"
            @click="$emit('toggle-mobile-menu')">
            ☰
        </button>
        <div class="topbar__title">
            <p class="topbar__eyebrow">
                Building Management System
            </p>

            <h1>{{ title }}</h1>
        </div>

        <div class="topbar__actions">
            <label class="topbar__search">
                <span aria-hidden="true">⌕</span>

                <input v-model="searchValue" type="search" placeholder="Search devices, floors..." aria-label="Search"
                    @keyup.enter="submitSearch" />
            </label>

            <div class="topbar__system-status">
                <span class="topbar__status-indicator"></span>
                <span>System operational</span>
            </div>


            <div class="topbar__user-wrapper">
                <button class="topbar__user" type="button" aria-label="Open user menu"
                    @click="isUserMenuOpen = !isUserMenuOpen">
                    <span class="topbar__avatar">
                        {{ userInitials }}
                    </span>

                    <span class="topbar__user-details">
                        <strong>{{ userName }}</strong>
                        <small>Facility Manager</small>
                    </span>

                    <span class="topbar__user-arrow" aria-hidden="true">
                        {{ isUserMenuOpen ? '▴' : '▾' }}
                    </span>
                </button>

                <UserMenu
                    v-if="isUserMenuOpen"
                    :user-name="userName"
                    @profile="openProfile"
                    @logout="logout"
                />
            </div>
        </div>
    </header>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import UserMenu from './UserMenu.vue';

const props = defineProps<{
    title: string;
    userName: string;
}>();

const emit = defineEmits<{
    search: [query: string];
    'open-profile': [];
    'toggle-mobile-menu': [];
    logout: [];
}>();

const searchValue = ref('');
const isUserMenuOpen = ref(false);

const userInitials = computed(() => {
    const cleanedName = props.userName.trim();

    if (!cleanedName) {
        return 'FM';
    }

    const parts = cleanedName
        .split(/\s+/)
        .filter(Boolean);

    if (parts.length === 1) {
        return parts[0].slice(0, 2).toUpperCase();
    }

    return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase();
});



function openProfile(): void {
    isUserMenuOpen.value = false;
    emit('open-profile');
}

function logout(): void {
    isUserMenuOpen.value = false;
    emit('logout');
}

function closeMenuOnEscape(event: KeyboardEvent): void {
    if (event.key === 'Escape') {
        isUserMenuOpen.value = false;
    }
}

onMounted(() => {
    window.addEventListener('keydown', closeMenuOnEscape);
});

onBeforeUnmount(() => {
    window.removeEventListener('keydown', closeMenuOnEscape);
});

function submitSearch(): void {
    emit('search', searchValue.value.trim());
}
</script>

<style scoped src="./TopBar.css"></style>