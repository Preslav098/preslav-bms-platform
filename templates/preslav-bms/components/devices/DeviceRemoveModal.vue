<template>
    <Teleport to="body">
        <Transition name="device-remove">
            <div v-if="device" class="device-remove" @click.self="$emit('close')">
                <section role="alertdialog" aria-modal="true" aria-labelledby="device-remove-title">
                    <span class="device-remove__icon" aria-hidden="true">!</span>
                    <p>Remove from Fleet Manager</p>
                    <h2 id="device-remove-title">Remove {{ device.name }}?</h2>
                    <div class="device-remove__warning">
                        This removes the device from this Fleet Manager instance. The physical device may reconnect and return to the waiting room until its Fleet Manager connection is disabled.
                    </div>
                    <dl>
                        <div><dt>Model</dt><dd>{{ device.model }}</dd></div>
                        <div><dt>Serial</dt><dd>{{ device.serial }}</dd></div>
                    </dl>
                    <footer>
                        <button type="button" :disabled="removing" @click="$emit('close')">Cancel</button>
                        <button class="device-remove__confirm" type="button" :disabled="removing" @click="$emit('confirm')">
                            {{ removing ? 'Removing…' : 'Remove device' }}
                        </button>
                    </footer>
                </section>
            </div>
        </Transition>
    </Teleport>
</template>

<script setup lang="ts">
import type { Device } from '../../models/Device';

defineProps<{ device: Device | null; removing: boolean }>();
defineEmits<{ close: []; confirm: [] }>();
</script>

<style scoped src="./DeviceRemoveModal.css"></style>
