<template>
    <Teleport to="body">
        <Transition name="device-enrollment">
            <div v-if="open" class="device-enrollment" @click.self="emit('close')">
                <section class="device-enrollment__dialog" role="dialog" aria-modal="true">
                    <header class="device-enrollment__header">
                        <div>
                            <p class="device-enrollment__eyebrow">Device onboarding</p>
                            <h2>Add a Shelly device</h2>
                            <p>Generate the official Fleet Manager enrollment link, then approve the device from the same BMS window.</p>
                        </div>
                        <button type="button" class="device-enrollment__close" @click="emit('close')">×</button>
                    </header>

                    <nav class="device-enrollment__tabs">
                        <button type="button" :class="{'is-active': mode === 'wifi'}" @click="mode = 'wifi'">Wi-Fi</button>
                        <button type="button" :class="{'is-active': mode === 'bluetooth'}" @click="mode = 'bluetooth'">Bluetooth</button>
                    </nav>

                    <section v-if="mode === 'wifi'" class="device-enrollment__form">
                        <template v-if="!tokenResult">
                            <div class="device-enrollment__notice">
                                <strong>Secure Wi-Fi onboarding</strong>
                                <span>The token is created by Fleet Manager through the template Host SDK.</span>
                            </div>
                            <label>
                                <span>Connection window</span>
                                <select v-model.number="validityMinutes">
                                    <option :value="15">15 minutes</option>
                                    <option :value="60">1 hour</option>
                                    <option :value="1440">24 hours</option>
                                </select>
                            </label>
                            <button class="device-enrollment__primary" type="button" :disabled="pending" @click="generateEnrollmentToken">
                                {{ pending ? 'Generating…' : 'Generate enrollment token' }}
                            </button>
                        </template>

                        <template v-else>
                            <p class="device-enrollment__warning">Copy now — the token is shown only once. <span v-if="expiresAtLabel">Expires {{ expiresAtLabel }}.</span></p>

                            <div class="device-enrollment__field">
                                <span>Outbound WebSocket server</span>
                                <div class="device-enrollment__copy-row">
                                    <input :value="tokenResult.url" readonly />
                                    <button type="button" class="device-enrollment__copy" @click="copyText(tokenResult.url, 'WebSocket URL')">Copy</button>
                                </div>
                            </div>

                            <ol class="device-enrollment__steps">
                                <li>Open the local Shelly web interface.</li>
                                <li>Open <strong>Networks → Outbound WebSocket</strong>.</li>
                                <li>Enable it and paste the complete WebSocket URL.</li>
                                <li>For a self-signed certificate, upload the Fleet Manager CA and select <strong>User TLS</strong>.</li>
                                <li>Save and wait for the device to appear below.</li>
                            </ol>

                            <div class="device-enrollment__waiting-header">
                                <div>
                                    <strong>Waiting Room</strong>
                                    <span>{{ pendingEntries.length }} pending</span>
                                </div>
                                <button type="button" class="device-enrollment__secondary" :disabled="loadingWaitingRoom" @click="loadWaitingRoom">
                                    {{ loadingWaitingRoom ? 'Checking…' : 'Check now' }}
                                </button>
                            </div>

                            <div v-if="pendingEntries.length === 0" class="device-enrollment__waiting-empty">
                                Waiting for the device to connect. This list refreshes automatically.
                            </div>

                            <article v-for="entry in pendingEntries" :key="entry.entryId" class="device-enrollment__pending-card">
                                <div>
                                    <strong>{{ entry.shellyID || entry.entryId }}</strong>
                                    <span>{{ entry.observedTransport || entry.securityModel || 'Shelly device' }}</span>
                                </div>
                                <button type="button" class="device-enrollment__primary device-enrollment__approve" :disabled="approvingEntryId === entry.entryId" @click="approveEntry(entry)">
                                    {{ approvingEntryId === entry.entryId ? 'Approving…' : 'Approve device' }}
                                </button>
                            </article>

                            <button type="button" class="device-enrollment__link-button" @click="resetToken">Generate another token</button>
                        </template>
                    </section>

                    <section v-else class="device-enrollment__form bluetooth-pairing">
                        <div class="bluetooth-pairing__hero">
                            <h2>Pair a sensor</h2>
                            <p>Scan, pair, add sensors and rename — all from this gateway. Sensors appear in the fleet immediately after they are added.</p>
                        </div>

                        <label>
                            <span>Bluetooth gateway</span>
                            <select v-model="bluetooth.gatewayId" required>
                                <option value="" disabled>Select a gateway</option>
                                <option v-for="gateway in bluetoothGateways" :key="gateway.shellyID" :value="gateway.shellyID">{{ gateway.name }} — {{ gateway.shellyID }}</option>
                            </select>
                        </label>

                        <div class="bluetooth-pairing__panel">
                            <p v-if="pairedCandidates.length === 0" class="bluetooth-pairing__empty">No paired BLE devices.</p>
                            <div class="bluetooth-pairing__label">Add Device</div>
                            <div class="bluetooth-pairing__manual">
                                <input v-model="manualMac" placeholder="MAC address (e.g. AA:BB:CC:DD:EE:FF)" @keyup.enter="pairManual" />
                                <button type="button" class="device-enrollment__primary" :disabled="pending || !bluetooth.gatewayId" @click="pairManual">Pair</button>
                            </div>
                            <button type="button" class="bluetooth-pairing__scan" :disabled="scanning || !bluetooth.gatewayId" @click="scanBluetooth">
                                {{ scanning ? `Scanning… ${scanSecondsLeft}s` : 'Scan for BLE Devices' }}
                            </button>

                            <div v-if="discoveredCandidates.length" class="bluetooth-pairing__discovered">
                                <div class="bluetooth-pairing__label">Discovered ({{ discoveredCandidates.length }})</div>
                                <article v-for="candidate in discoveredCandidates" :key="candidate.stableId" class="bluetooth-pairing__device">
                                    <span class="bluetooth-pairing__icon">ᛒ</span>
                                    <div><strong>{{ candidate.productName || candidate.name || candidate.modelId || 'Bluetooth device' }}</strong><small>{{ candidate.modelId || 'BTHome' }} / {{ candidate.bleAddress }}</small></div>
                                    <button type="button" class="device-enrollment__primary" :disabled="pairingStableId === candidate.stableId" @click="addCandidate(candidate)">{{ pairingStableId === candidate.stableId ? 'Adding…' : 'Add' }}</button>
                                </article>
                            </div>
                        </div>
                    </section>

                    <p v-if="message" class="device-enrollment__message" :class="{'device-enrollment__message--error': error}">{{ message }}</p>

                    <footer class="device-enrollment__footer">
                        <button type="button" class="device-enrollment__secondary" @click="emit('close')">Done</button>
                    </footer>
                </section>
            </div>
        </Transition>
    </Teleport>
</template>

<script setup lang="ts">
import {computed, onBeforeUnmount, reactive, ref, watch} from 'vue';
import {bluetoothDevices, call, type HostDevice} from '@host/index';

const props = defineProps<{open: boolean; devices: HostDevice[]}>();
const emit = defineEmits<{close: []; added: []}>();

interface EnrollmentTokenResult { url: string; tokenOnce: string; expiresAt: string; }
interface WaitingRoomEntry {
    entryId: string;
    waitingRoomId?: string;
    waitingRoomKind?: string;
    shellyID?: string;
    profileId?: string | null;
    observedTransport?: string;
    securityModel?: string;
}

const mode = ref<'wifi' | 'bluetooth'>('wifi');
const pending = ref(false);
const loadingWaitingRoom = ref(false);
const approvingEntryId = ref('');
const message = ref('');
const error = ref(false);
const validityMinutes = ref(15);
const tokenResult = ref<EnrollmentTokenResult | null>(null);
const pendingEntries = ref<WaitingRoomEntry[]>([]);
const bluetooth = reactive({gatewayId: ''});
const bluetoothGateways = ref<Array<{shellyID: string; name: string}>>([]);
const discoveredCandidates = ref<any[]>([]);
const discoverySeen = new Map<string, any>();
const pairedCandidates = ref<any[]>([]);
const manualMac = ref('');
const scanning = ref(false);
const scanSecondsLeft = ref(0);
const pairingStableId = ref('');
let scanTimer: ReturnType<typeof setInterval> | null = null;
let pollingTimer: ReturnType<typeof setInterval> | null = null;

const gatewayDevices = computed(() => props.devices.filter((device) => {
    if (!device.online || !getShellyId(device)) return false;
    const text = `${device.type ?? ''} ${device.model ?? ''} ${device.name ?? ''}`.toLowerCase();
    return !text.includes('blu') && !text.includes('bthome');
}));

const expiresAtLabel = computed(() => {
    const raw = tokenResult.value?.expiresAt;
    if (!raw) return '';
    const date = new Date(raw);
    return Number.isNaN(date.getTime()) ? raw : date.toLocaleString();
});

watch(() => props.open, (isOpen) => {
    if (isOpen) {
        message.value = '';
        void loadBluetoothGateways();
        error.value = false;
        if (!bluetooth.gatewayId && gatewayDevices.value[0]) bluetooth.gatewayId = getShellyId(gatewayDevices.value[0]);
        if (tokenResult.value) startPolling();
    } else {
        stopPolling();
    }
});

onBeforeUnmount(() => { stopPolling(); if (scanTimer) clearInterval(scanTimer); });

async function generateEnrollmentToken(): Promise<void> {
    await run(async () => {
        const result = await call<EnrollmentTokenResult>('deviceIngress', ['EnrollmentToken', 'Create'], {
            validityMinutes: validityMinutes.value
        });
        if (!result?.url || !result?.tokenOnce) throw new Error('Fleet Manager returned an invalid enrollment-token response.');
        tokenResult.value = result;
        message.value = 'Enrollment token generated. Configure the device and keep this window open.';
        await loadWaitingRoom();
        startPolling();
    });
}

async function loadWaitingRoom(): Promise<void> {
    if (loadingWaitingRoom.value) return;
    loadingWaitingRoom.value = true;
    try {
        const response = await call<Record<string, WaitingRoomEntry>>('waitingroom', ['GetPending'], {});
        pendingEntries.value = Object.values(response ?? {}).filter((entry) => Boolean(entry?.entryId));
    } catch (caught) {
        error.value = true;
        message.value = formatHostError(caught);
    } finally {
        loadingWaitingRoom.value = false;
    }
}

async function approveEntry(entry: WaitingRoomEntry): Promise<void> {
    approvingEntryId.value = entry.entryId;
    message.value = '';
    error.value = false;
    try {
        await call('waitingroom', ['Approve'], {
            entryId: entry.entryId,
            action: 'create_new_device',
            ...(entry.profileId ? {profileId: entry.profileId} : {})
        });
        message.value = `${entry.shellyID || 'Device'} approved successfully.`;
        await loadWaitingRoom();
        emit('added');
    } catch (caught) {
        error.value = true;
        message.value = formatHostError(caught);
    } finally {
        approvingEntryId.value = '';
    }
}

function startPolling(): void {
    stopPolling();
    pollingTimer = setInterval(() => void loadWaitingRoom(), 3000);
}

function stopPolling(): void {
    if (pollingTimer) clearInterval(pollingTimer);
    pollingTimer = null;
}

async function copyText(text: string, label: string): Promise<void> {
    try {
        await navigator.clipboard.writeText(text);
        error.value = false;
        message.value = `${label} copied.`;
    } catch {
        error.value = true;
        message.value = `Could not copy ${label.toLowerCase()}. Copy it manually.`;
    }
}

function resetToken(): void {
    tokenResult.value = null;
    pendingEntries.value = [];
    message.value = '';
    error.value = false;
    stopPolling();
}

async function loadBluetoothGateways(): Promise<void> {
    try {
        const result = await bluetoothDevices.listGateways();
        bluetoothGateways.value = result?.items ?? [];
        if (!bluetooth.gatewayId && bluetoothGateways.value[0]) bluetooth.gatewayId = bluetoothGateways.value[0].shellyID;
    } catch (caught) {
        error.value = true;
        message.value = formatHostError(caught);
    }
}

async function loadBluetoothCandidates(): Promise<void> {
    if (!bluetooth.gatewayId) return;
    const result = await bluetoothDevices.listCandidates({
        gatewayExternalId: bluetooth.gatewayId,
        limit: 100,
        offset: 0
    });
    const items = result?.items ?? [];
    pairedCandidates.value = items.filter((item) => item.alreadyPromoted);

    // Candidate.List contains gateway children that are already known by the gateway.
    // Keep live discovery results too, so the user sees devices immediately while scanning.
    for (const item of items.filter((candidate) => !candidate.alreadyPromoted)) {
        const mac = normalizeMac(item.bleAddress || '');
        if (mac) discoverySeen.set(mac, {...item, bleAddress: mac});
    }
    discoveredCandidates.value = Array.from(discoverySeen.values());
}

async function pollDiscoveryStatus(): Promise<void> {
    if (!bluetooth.gatewayId) return;
    try {
        const status = await call<Record<string, unknown>>('bthome', ['GetStatus'], {
            shellyID: bluetooth.gatewayId
        });
        collectDiscoveredDevices(status);
    } catch {
        // Some gateway firmware versions expose discoveries only as websocket events.
        // Candidate.List remains the safe Host SDK fallback.
    }
    await loadBluetoothCandidates();
}

function collectDiscoveredDevices(value: unknown): void {
    const visited = new Set<unknown>();
    const visit = (node: unknown): void => {
        if (!node || typeof node !== 'object' || visited.has(node)) return;
        visited.add(node);
        if (Array.isArray(node)) {
            node.forEach(visit);
            return;
        }
        const record = node as Record<string, any>;
        const rawMac = record.mac ?? record.addr ?? record.address ?? record.bleAddress;
        const mac = normalizeMac(String(rawMac ?? ''));
        if (mac) {
            const manufacturer = record.shelly_mfdata ?? record.shellyMfdata ?? {};
            discoverySeen.set(mac, {
                stableId: mac,
                bleAddress: mac,
                name: record.local_name ?? record.localName ?? record.name ?? null,
                productName: record.productName ?? manufacturer?.product_name ?? manufacturer?.productName ?? null,
                modelId: record.modelId ?? record.modelString ?? manufacturer?.model ?? null,
                rssi: typeof record.rssi === 'number' ? record.rssi : null
            });
        }
        Object.values(record).forEach(visit);
    };
    visit(value);
    discoveredCandidates.value = Array.from(discoverySeen.values());
}

async function scanBluetooth(): Promise<void> {
    if (!bluetooth.gatewayId || scanning.value) return;
    scanning.value = true;
    scanSecondsLeft.value = 10;
    discoverySeen.clear();
    discoveredCandidates.value = [];
    message.value = 'Scanning… press the physical button on the BLU sensor now.';
    error.value = false;
    try {
        await call('bthome', ['StartDiscovery'], {
            shellyID: bluetooth.gatewayId,
            duration: 10
        });
        await pollDiscoveryStatus();
        scanTimer = setInterval(() => {
            scanSecondsLeft.value = Math.max(0, scanSecondsLeft.value - 1);
            void pollDiscoveryStatus();
            if (scanSecondsLeft.value === 0) {
                if (scanTimer) clearInterval(scanTimer);
                scanTimer = null;
                scanning.value = false;
                message.value = discoveredCandidates.value.length
                    ? `Scan complete — found ${discoveredCandidates.value.length} device(s).`
                    : 'Scan complete — no devices found. Press the sensor button and scan again.';
            }
        }, 1000);
    } catch (caught) {
        scanning.value = false;
        error.value = true;
        message.value = formatHostError(caught);
    }
}

async function pairManual(): Promise<void> {
    const mac = manualMac.value.trim().toUpperCase();
    if (!/^([0-9A-F]{2}:){5}[0-9A-F]{2}$/.test(mac)) { error.value = true; message.value = 'Invalid MAC address.'; return; }
    await run(async () => {
        await call('bthome', ['Device', 'AddManual'], {shellyID: bluetooth.gatewayId, mac});
        manualMac.value = '';
        await loadBluetoothCandidates();
    });
}

async function addCandidate(candidate: any): Promise<void> {
    pairingStableId.value = candidate.stableId || candidate.bleAddress;
    try {
        const mac = normalizeMac(candidate.bleAddress || candidate.mac || candidate.addr || '');
        if (!mac) throw new Error('The discovered device has no valid Bluetooth MAC address.');

        const pairResult = await call<{success: true; alreadyPaired: boolean}>('bthome', ['Device', 'AddManual'], {
            shellyID: bluetooth.gatewayId,
            mac,
            productName: candidate.productName || candidate.name || undefined,
            modelId: candidate.modelId || undefined
        });

        // Wait briefly for the gateway configuration to reach Fleet Manager,
        // then promote the new BTHome child to a first-class fleet device.
        await delay(1200);
        const candidates = await bluetoothDevices.listCandidates({
            gatewayExternalId: bluetooth.gatewayId,
            limit: 100,
            offset: 0
        });
        const match = candidates.items.find((item) =>
            normalizeMac(item.bleAddress || '') === mac
        );
        if (match && !match.alreadyPromoted) {
            await bluetoothDevices.promoteFromGateway({
                gatewayExternalId: match.gatewayExternalId,
                componentKey: match.componentKey,
                makePrimary: true
            });
        }

        discoverySeen.delete(mac);
        discoveredCandidates.value = Array.from(discoverySeen.values());
        message.value = pairResult?.alreadyPaired
            ? `${candidate.productName || candidate.name || mac} was already paired and is now synchronized.`
            : `${candidate.productName || candidate.name || mac} paired and added successfully.`;
        error.value = false;
        await loadBluetoothCandidates();
        emit('added');
    } catch (caught) {
        error.value = true;
        message.value = formatHostError(caught);
    } finally {
        pairingStableId.value = '';
    }
}

async function run(action: () => Promise<void>): Promise<void> {
    if (pending.value) return;
    pending.value = true;
    message.value = '';
    error.value = false;
    try { await action(); }
    catch (caught) {
        error.value = true;
        message.value = formatHostError(caught);
    } finally { pending.value = false; }
}

function normalizeMac(value: string): string {
    const compact = value.replace(/[^0-9a-f]/gi, '').toUpperCase();
    if (compact.length !== 12) return '';
    return compact.match(/.{2}/g)?.join(':') ?? '';
}

function delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

function formatHostError(caught: unknown): string {
    if (caught instanceof Error && caught.message) return caught.message;
    if (typeof caught === 'string') return caught;
    if (caught && typeof caught === 'object') {
        const value = caught as Record<string, any>;
        const nested = value.message ?? value.error?.message ?? value.error ?? value.data?.message ?? value.reason;
        if (typeof nested === 'string' && nested.trim()) return nested;
        try {
            return JSON.stringify(caught, null, 2);
        } catch {
            return 'Bluetooth operation failed. Check Fleet Manager logs for details.';
        }
    }
    return 'Bluetooth operation failed.';
}

function getShellyId(device: HostDevice): string {
    const record = device as unknown as Record<string, unknown>;
    return String(record.shellyID ?? record.shellyId ?? record.serial ?? device.id ?? '');
}
</script>

<style scoped src="./DeviceEnrollmentModal.css"></style>
