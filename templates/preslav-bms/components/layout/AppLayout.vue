<template>
    <div class="app-layout" :class="{
        'app-layout--sidebar-collapsed': sidebarCollapsed
    }">
        <div class="app-layout__desktop-sidebar">
            <Sidebar :active-page="activePage" :collapsed="sidebarCollapsed" @navigate="handleNavigation"
                @update:collapsed="sidebarCollapsed = $event" />
        </div>

        <div class="app-layout__main">
            <TopBar
                :title="title"
                :user-name="userName"
                @toggle-mobile-menu="mobileMenuOpen = true"
                @search="handleSearch"
                @open-profile="handleOpenProfile"
                @logout="handleLogout"
            />

            <main class="app-layout__content">
                <slot />
            </main>
        </div>

        <div v-if="mobileMenuOpen" class="app-layout__mobile-overlay" role="presentation"
            @click="mobileMenuOpen = false">
            <aside class="app-layout__mobile-drawer" aria-label="Mobile navigation" @click.stop>
                <Sidebar :active-page="activePage" :collapsed="sidebarCollapsed" :mobile="true" @navigate="handleMobileNavigation"
                    @update:collapsed="sidebarCollapsed = $event" />
            </aside>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';

import Sidebar from './Sidebar.vue';
import TopBar from './TopBar.vue';

defineProps<{
    activePage: string;
    title: string;
    userName: string;
}>();

const emit = defineEmits<{
    navigate: [page: string];
    search: [query: string];
    'open-profile': [];
    logout: [];
}>();

const sidebarCollapsed = ref(false);
const mobileMenuOpen = ref(false);

function handleNavigation(page: string): void {
    emit('navigate', page);
}

function handleMobileNavigation(page: string): void {
    emit('navigate', page);
    mobileMenuOpen.value = false;
}

function handleSearch(query: string): void {
    emit('search', query);
}


function handleOpenProfile(): void {
    emit('open-profile');
}


function handleLogout(): void {
    emit('logout');
}
</script>

<style scoped src="./AppLayout.css"></style>
