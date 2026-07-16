<template>
    <section class="dashboard">
        <DashboardHeader :refreshing="refreshing" @refresh="$emit('refresh')" />

        <DashboardStats :total-devices="devices.length" :online-devices="onlineCount" :offline-devices="offlineCount"
            :total-groups="groups.length" />

        <QuickActions @open-devices="$emit('navigate', 'devices')" @open-floors="$emit('navigate', 'floors')"
            @open-energy="$emit('navigate', 'energy')" @open-climate="$emit('navigate', 'climate')" />

        <div class="dashboard__content-grid">
            <article class="dashboard__panel">
                <header class="dashboard__panel-header">
                    <div>
                        <p class="dashboard__eyebrow">
                            Infrastructure
                        </p>

                        <h3>Recent devices</h3>
                    </div>

                    <span class="dashboard__count">
                        {{ devices.length }}
                    </span>
                </header>

                <div v-if="devices.length === 0" class="dashboard__empty-state">
                    <strong>No devices available</strong>

                    <p>
                        Devices will appear after they are added and approved
                        in Fleet Manager.
                    </p>
                </div>

                <div v-else class="dashboard__device-list">
                    <button v-for="device in visibleDevices" :key="String(device.id)" class="dashboard__device-row"
                        type="button" @click="$emit('select-device', device)">
                        <span class="dashboard__status-dot" :class="{
                            'dashboard__status-dot--online': device.online,
                            'dashboard__status-dot--offline': !device.online
                        }"></span>

                        <span class="dashboard__device-information">
                            <strong>{{ getDeviceName(device) }}</strong>
                            <small>{{ getDeviceModel(device) }}</small>
                        </span>

                        <span class="dashboard__device-status" :class="{
                            'dashboard__device-status--online':
                                device.online
                        }">
                            {{ device.online ? 'Online' : 'Offline' }}
                        </span>
                    </button>
                </div>
            </article>

            <article class="dashboard__panel">
                <header class="dashboard__panel-header">
                    <div>
                        <p class="dashboard__eyebrow">
                            Building structure
                        </p>

                        <h3>Floors and groups</h3>
                    </div>

                    <span class="dashboard__count">
                        {{ groups.length }}
                    </span>
                </header>

                <div v-if="groups.length === 0" class="dashboard__empty-state">
                    <strong>No floors configured</strong>

                    <p>
                        Create Fleet Manager groups for each building floor.
                    </p>
                </div>

                <div v-else class="dashboard__floor-list">
                    <button v-for="group in visibleGroups" :key="String(group.id)" class="dashboard__floor-row"
                        type="button" @click="$emit('select-floor', group)">
                        <span class="dashboard__floor-icon">
                            {{ getGroupInitial(group) }}
                        </span>

                        <span class="dashboard__floor-information">
                            <strong>{{ getGroupName(group) }}</strong>
                            <small>Building floor</small>
                        </span>

                        <span class="dashboard__arrow">
                            →
                        </span>
                    </button>
                </div>
            </article>
        </div>
    </section>
</template>

<script setup lang="ts">
import { computed } from 'vue';

import DashboardHeader from './DashboardHeader.vue';
import DashboardStats from './DashboardStats.vue';
import QuickActions from './QuickActions.vue';

import type {UnknownRecord} from '../../models/Common';
import type {Device} from '../../models/Device';
import type {Group} from '../../models/Group';
import type {PageId} from '../../models/Page';

const props = defineProps<{
    devices: Device[];
    groups: Group[];
    refreshing: boolean;
}>();

defineEmits<{
    refresh: [];
    navigate: [page: PageId];
    'select-device': [device: Device];
    'select-floor': [group: Group];
}>();

const onlineCount = computed(() => {
    return props.devices.filter((device) => device.online).length;
});

const offlineCount = computed(() => {
    return props.devices.length - onlineCount.value;
});

const visibleDevices = computed(() => {
    return props.devices.slice(0, 6);
});

const visibleGroups = computed(() => {
    return props.groups.slice(0, 6);
});

function readStringProperty(
    value: unknown,
    propertyNames: string[]
): string | undefined {
    if (typeof value !== 'object' || value === null) {
        return undefined;
    }

    const record = value as UnknownRecord;

    for (const propertyName of propertyNames) {
        const propertyValue = record[propertyName];

        if (
            typeof propertyValue === 'string' &&
            propertyValue.trim().length > 0
        ) {
            return propertyValue;
        }
    }

    return undefined;
}

function getDeviceName(device: Device): string {
    return (
        readStringProperty(device, [
            'name',
            'displayName',
            'hostname',
            'deviceName'
        ]) ?? 'Unnamed device'
    );
}

function getDeviceModel(device: Device): string {
    return (
        readStringProperty(device, [
            'model',
            'deviceModel',
            'type',
            'generation'
        ]) ?? 'Unknown model'
    );
}

function getGroupName(group: Group): string {
    return (
        readStringProperty(group, [
            'name',
            'displayName',
            'title'
        ]) ?? 'Unnamed floor'
    );
}

function getGroupInitial(group: Group): string {
    return getGroupName(group).charAt(0).toUpperCase();
}
</script>

<style scoped src="./Dashboard.css"></style>