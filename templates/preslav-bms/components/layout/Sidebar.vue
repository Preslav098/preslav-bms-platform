<template>
    <aside class="sidebar" :class="{
        'sidebar--collapsed': collapsed && !mobile,
        'sidebar--mobile': mobile
    }">
        <header class="sidebar__header">
            <div class="sidebar__brand">
                <span class="sidebar__logo" aria-hidden="true">
                    B
                </span>

                <div class="sidebar__brand-text">
                    <strong>Preslav BMS</strong>
                    <small>Building Management</small>
                </div>
            </div>

            <button v-if="!mobile" class="sidebar__collapse-button" type="button" :aria-label="collapsed
                    ? 'Expand navigation'
                    : 'Collapse navigation'
                " :title="collapsed
                        ? 'Expand navigation'
                        : 'Collapse navigation'
                    " @click="$emit('update:collapsed', !collapsed)">
                <span class="sidebar__collapse-icon" :class="{
                    'sidebar__collapse-icon--collapsed': collapsed
                }" aria-hidden="true">
                    ‹
                </span>
            </button>
        </header>

        <nav class="sidebar__navigation" aria-label="Main navigation">
            <p class="sidebar__section-label">
                Navigation
            </p>

            <button v-for="item in navigationItems" :key="item.id" class="sidebar__navigation-item" :class="{
                'sidebar__navigation-item--active':
                    activePage === item.id
            }" type="button" :title="collapsed && !mobile
                        ? item.label
                        : undefined
                    " @click="$emit('navigate', item.id)">
                <span class="sidebar__navigation-icon" aria-hidden="true">
                    {{ item.icon }}
                </span>

                <span class="sidebar__navigation-label">
                    {{ item.label }}
                </span>

                <span v-if="item.badge && item.badge > 0" class="sidebar__navigation-badge">
                    {{ formatBadge(item.badge) }}
                </span>
            </button>
        </nav>

        <footer class="sidebar__footer">
            <div class="sidebar__connection">
                <span class="sidebar__connection-dot"></span>

                <div class="sidebar__connection-text">
                    <strong>Connected</strong>
                    <small>Fleet Manager online</small>
                </div>
            </div>

            <div class="sidebar__version">
                <span>Preslav BMS</span>
                <small>v1.0.0</small>
            </div>
        </footer>
    </aside>
</template>

<script setup lang="ts">
import type { PageId } from '../../models/Page';

interface NavigationItem {
    id: PageId;
    label: string;
    icon: string;
    badge?: number;
}

withDefaults(
    defineProps<{
        activePage: PageId;
        collapsed?: boolean;
        mobile?: boolean;
    }>(),
    {
        collapsed: false,
        mobile: false
    }
);

defineEmits<{
    navigate: [page: PageId];
    'update:collapsed': [collapsed: boolean];
}>();

const navigationItems: NavigationItem[] = [
    {
        id: 'overview',
        label: 'Overview',
        icon: '⌂'
    },
    {
        id: 'building',
        label: 'Building',
        icon: '▤'
    },
    {
        id: 'floors',
        label: 'Floor Plans',
        icon: '⌗'
    },
    {
        id: 'devices',
        label: 'Devices',
        icon: '◉'
    },
    {
        id: 'energy',
        label: 'Energy',
        icon: 'ϟ'
    },
    {
        id: 'climate',
        label: 'Climate',
        icon: '◌'
    },
    {
        id: 'events',
        label: 'Door / Window',
        icon: '!'
    }
];

function formatBadge(value: number): string {
    return value > 99
        ? '99+'
        : String(value);
}
</script>

<style scoped src="./Sidebar.css"></style>