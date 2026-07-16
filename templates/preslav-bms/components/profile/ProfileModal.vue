<template>
    <Teleport to="body">
        <Transition name="profile-modal">
            <div
                v-if="open"
                class="profile-modal"
                role="presentation"
                @click.self="$emit('close')"
            >
                <section
                    class="profile-modal__dialog"
                    role="dialog"
                    aria-modal="true"
                    aria-labelledby="profile-modal-title"
                >
                    <header class="profile-modal__header">
                        <div class="profile-modal__identity">
                            <span class="profile-modal__avatar" aria-hidden="true">
                                {{ initials }}
                            </span>

                            <div>
                                <p>Account profile</p>
                                <h2 id="profile-modal-title">{{ userName }}</h2>
                                <span>Facility Manager</span>
                            </div>
                        </div>

                        <button
                            class="profile-modal__close"
                            type="button"
                            aria-label="Close profile"
                            @click="$emit('close')"
                        >
                            ×
                        </button>
                    </header>

                    <div class="profile-modal__body">
                        <div class="profile-modal__section-heading">
                            <p>User information</p>
                            <h3>Profile details</h3>
                        </div>

                        <dl class="profile-modal__details">
                            <div>
                                <dt>Name</dt>
                                <dd>{{ userName }}</dd>
                            </div>

                            <div>
                                <dt>Email</dt>
                                <dd>{{ email || 'Not available' }}</dd>
                            </div>

                            <div>
                                <dt>Role</dt>
                                <dd>Facility Manager</dd>
                            </div>

                            <div>
                                <dt>Platform</dt>
                                <dd>Preslav BMS</dd>
                            </div>
                        </dl>

                        <div class="profile-modal__notice">
                            <span aria-hidden="true">✓</span>
                            <div>
                                <strong>Fleet Manager account</strong>
                                <p>
                                    Authentication and account permissions are managed by Fleet Manager.
                                </p>
                            </div>
                        </div>
                    </div>

                    <footer class="profile-modal__footer">
                        <button type="button" @click="$emit('close')">
                            Close
                        </button>
                    </footer>
                </section>
            </div>
        </Transition>
    </Teleport>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
    open: boolean;
    userName: string;
    email?: string;
}>();

defineEmits<{
    close: [];
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

<style scoped src="./ProfileModal.css"></style>
