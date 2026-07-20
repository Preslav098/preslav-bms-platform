<template>
    <AppLayout :active-page="activePage" :title="pageTitle" :user-name="currentUserName" @navigate="handleNavigation"
        @search="handleSearch" @open-profile="handleOpenProfile" @logout="handleLogout">
        <BuildingOverview v-if="activePage === 'overview'" :devices="deviceList" :host-devices="hostDevices"
            :floors="floorList" :refreshing="refreshing" @refresh="refreshData" @navigate="handleNavigation"
            @select-device="openDeviceDetails" @select-floor="handleBuildingFloorSelection" />

        <BuildingPage v-else-if="activePage === 'building'" :floors="floorList" :devices="deviceList"
            @open-floors="activePage = 'floors'" @select-floor="handleBuildingFloorSelection" />

        <FloorPage v-else-if="activePage === 'floors'" :floors="floorList" @select-device="openDeviceDetails" />

        <DevicePage v-else-if="activePage === 'devices'" :devices="deviceList" :host-devices="hostDevices"
            :refreshing="refreshing" @refresh="refreshData" @select-device="openDeviceDetails"
            @remove-device="openRemoveDeviceModal" @add-device="enrollmentOpen = true" />
        <EnergyPage v-else-if="activePage === 'energy'" :devices="deviceList" :refreshing="refreshing"
            @refresh="refreshData" />

        <ClimatePage v-else-if="activePage === 'climate'" :devices="hostDevices" :refreshing="refreshing"
            @refresh="refreshData" />

        <DoorPage v-else-if="activePage === 'events'" :devices="hostDevices" :refreshing="refreshing"
            @refresh="refreshData" />
        <DevicePopup :device="selectedDevice" :host-device="selectedHostDevice" @close="closeDeviceDetails"
            @updated="refreshData" />

        <DeviceEnrollmentModal :open="enrollmentOpen" :devices="hostDevices" @close="enrollmentOpen = false"
            @added="handleDeviceAdded" />
        <DeviceRemoveModal :device="devicePendingRemoval" :removing="removingDevice" @close="closeRemoveDeviceModal"
            @confirm="confirmRemoveDevice" />

        <ProfileModal :open="profileOpen" :user-name="currentUserName" :email="currentUserEmail"
            @close="profileOpen = false" />
    </AppLayout>
</template>

<script setup lang="ts">
import {
    bluetoothDevices,
    devices as deviceApi,
    useCurrentUser,
    useCustomization,
    useDevices,
    useGroups
} from '@host/index';
import {
    computed,
    onMounted,
    ref,
    watch,
    watchEffect
} from 'vue';
import DeviceRemoveModal from './components/devices/DeviceRemoveModal.vue';

import AppLayout from './components/layout/AppLayout.vue';
import BuildingOverview from './components/overview/BuildingOverview.vue';
import BuildingPage from './components/building/BuildingPage.vue';
import FloorPage from './components/floors/FloorPage.vue';
import DevicePage from './components/devices/DevicePage.vue';
import EnergyPage from './components/energy/EnergyPage.vue';
import ClimatePage from './components/climate/ClimatePage.vue';
import DoorPage from './components/door/DoorPage.vue';
import DevicePopup from './components/devices/DevicePopup.vue';
import DeviceEnrollmentModal from './components/devices/DeviceEnrollmentModal.vue';
import ProfileModal from './components/profile/ProfileModal.vue';

import type { Device } from './models/Device';
import type { Floor } from './models/Floor';
import type { UnknownRecord } from './models/Common';

import {
    PAGE_IDS,
    type PageId
} from './models/Page';

import { mapHostDevices } from './services/deviceMapper';
import { mapHostGroupsToFloors } from './services/floorMapper';

import {
    extractBluDoor,
    isBluDoorDevice
} from './utils/bthome';

const customization = useCustomization();
const currentUser = useCurrentUser();
const devices = useDevices();
const groups = useGroups();

const ACTIVE_PAGE_STORAGE_KEY = 'preslav-bms-active-page';

const activePage = ref<PageId>(readStoredActivePage());
const refreshing = ref(false);
const selectedDevice = ref<Device | null>(null);
const profileOpen = ref(false);
const enrollmentOpen = ref(false);
const devicePendingRemoval = ref<Device | null>(null);
const removingDevice = ref(false);

const hostDevices = computed(() => {
    return devices.data.value;
});
const selectedHostDevice = computed(() => {
    if (!selectedDevice.value) {
        return null;
    }

    return hostDevices.value.find(
        (hostDevice) => {
            return (
                String(hostDevice.id) ===
                String(selectedDevice.value?.id)
            );
        }
    ) ?? null;
});

const deviceList = computed<Device[]>(() => {
    return mapHostDevices(
        devices.data.value
    );
});



const floorList = computed<Floor[]>(() => {
    return mapHostGroupsToFloors(
        groups.data.value,
        deviceList.value
    );
});

const currentUserName = computed(() => {
    return (
        readStringProperty(
            currentUser,
            [
                'name',
                'username',
                'email'
            ]
        ) ?? 'Facility Manager'
    );
});

const currentUserEmail = computed(() => {
    return readStringProperty(
        currentUser,
        ['email', 'username']
    );
});

const pageTitle = computed<string>(() => {
    const configuredTitle = readStringProperty(
        customization,
        ['title']
    );

    if (
        configuredTitle &&
        (
            activePage.value === 'overview'
        )
    ) {
        return configuredTitle;
    }

    return getPageTitle(
        activePage.value
    );
});


watch(
    activePage,
    (page) => {
        try {
            window.localStorage.setItem(
                ACTIVE_PAGE_STORAGE_KEY,
                page
            );
        } catch (error) {
            console.warn(
                'Could not persist the active BMS page:',
                error
            );
        }
    }
);

watchEffect(() => {
    const doorDevice = hostDevices.value.find(
        isBluDoorDevice
    );

    console.info(
        'BLU Door live reading:',
        doorDevice
            ? extractBluDoor(doorDevice)
            : null
    );
});
function openRemoveDeviceModal(device: Device): void {
    devicePendingRemoval.value = device;
}

function closeRemoveDeviceModal(): void {
    if (removingDevice.value) {
        return;
    }

    devicePendingRemoval.value = null;
}

async function confirmRemoveDevice(): Promise<void> {
    const device = devicePendingRemoval.value;

    if (!device || removingDevice.value) {
        return;
    }

    removingDevice.value = true;

    try {
        const externalId = String(device.id);

        const isBluetooth =
            externalId.startsWith('blu_') ||
            device.source === 'bluetooth' ||
            device.raw?.source === 'bluetooth';

        if (isBluetooth) {
            await bluetoothDevices.delete({
                externalId: String(device.id),
                unpairFromGateway: true
            });

            const removedId = String(device.id);

            devices.data.value = devices.data.value.filter((hostDevice) => {
                const hostId = String(
                    hostDevice.id ??
                    hostDevice.shellyID ??
                    hostDevice.externalId ??
                    ''
                );

                return hostId !== removedId;
            });

            devicePendingRemoval.value = null;

            await devices.refresh();
            console.info(
                devices.data.value,
            );
        } else {
            await deviceApi.delete(externalId);
        }

        if (
            selectedDevice.value &&
            String(selectedDevice.value.id) === externalId
        ) {
            closeDeviceDetails();
        }

        devicePendingRemoval.value = null;

        await devices.refresh();
    } catch (error) {
        console.error('Could not remove device:', error);

        window.alert(
            `Could not remove device: ${getErrorMessage(error)}`
        );
    } finally {
        removingDevice.value = false;
    }
}

function getErrorMessage(error: unknown): string {
    if (error instanceof Error) {
        return error.message;
    }

    if (typeof error === 'string') {
        return error;
    }

    if (
        error &&
        typeof error === 'object'
    ) {
        const record = error as Record<string, unknown>;

        for (const key of [
            'message',
            'error',
            'detail',
            'reason'
        ]) {
            const value = record[key];

            if (typeof value === 'string') {
                return value;
            }
        }

        try {
            return JSON.stringify(error);
        } catch {
            return 'Unknown Fleet Manager error';
        }
    }

    return 'Unknown Fleet Manager error';
}


function readStoredActivePage(): PageId {
    try {
        const storedPage = window.localStorage.getItem(
            ACTIVE_PAGE_STORAGE_KEY
        );

        if (
            storedPage &&
            isPageId(storedPage)
        ) {
            return storedPage;
        }
    } catch (error) {
        console.warn(
            'Could not restore the active BMS page:',
            error
        );
    }

    return 'overview';
}

function getPageTitle(
    page: PageId
): string {
    switch (page) {
        case 'overview':
            return 'Building Overview';

        case 'building':
            return '3D Building';

        case 'floors':
            return 'Floor Plans';

        case 'devices':
            return 'Devices';

        case 'energy':
            return 'Energy Monitoring';

        case 'climate':
            return 'Climate Monitoring';

        case 'events':
            return 'Door and Window Monitoring';

        default: {
            const exhaustiveCheck: never = page;
            return exhaustiveCheck;
        }
    }
}


function readStringProperty(
    value: unknown,
    propertyNames: readonly string[]
): string | undefined {
    if (
        typeof value !== 'object' ||
        value === null
    ) {
        return undefined;
    }

    const record = value as UnknownRecord;

    for (const propertyName of propertyNames) {
        const propertyValue =
            record[propertyName];

        if (
            typeof propertyValue === 'string' &&
            propertyValue.trim().length > 0
        ) {
            return propertyValue.trim();
        }
    }

    return undefined;
}

function handleNavigation(
    page: string
): void {
    if (!isPageId(page)) {
        console.warn(
            'Unknown BMS page:',
            page
        );

        return;
    }

    activePage.value = page;
}

function handleSearch(): void {
    activePage.value = 'devices';
}

function openDeviceDetails(
    device: Device
): void {
    selectedDevice.value = device;
}

function closeDeviceDetails(): void {
    selectedDevice.value = null;
}

function handleBuildingFloorSelection(
    floor: Floor
): void {
    console.info(
        'Selected building floor:',
        floor
    );

    activePage.value = 'floors';
}


async function handleDeviceAdded(): Promise<void> {
    await refreshData();
}

function handleOpenProfile(): void {
    profileOpen.value = true;
}


function handleLogout(): void {
    console.info(
        'Logout requested'
    );
}

function isPageId(
    page: string
): page is PageId {
    return PAGE_IDS.some(
        (pageId) => pageId === page
    );
}

async function refreshData(): Promise<void> {
    if (refreshing.value) {
        return;
    }

    refreshing.value = true;

    try {
        await Promise.all([
            devices.refresh(),
            groups.refresh()
        ]);
    } catch (error) {
        console.error(
            'Failed to refresh BMS data:',
            error
        );
    } finally {
        refreshing.value = false;
    }
}

onMounted(() => {
    void refreshData();
});
</script>

<style scoped src="./index.css"></style>
