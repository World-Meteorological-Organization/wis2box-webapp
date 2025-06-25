<template>
    <v-row class="justify-center">
        <v-card class="max-form-width">
            <v-card-item>
                <span v-html="homeContent"></span>
            </v-card-item>
            <v-card-item v-if="errorMessage">
                <v-alert type="error" dismissible>
                    {{ errorMessage }}
                </v-alert>
            </v-card-item>
        </v-card>
    </v-row>
</template>

<script setup>

import { ref } from 'vue';

const homeContent = ref('<h2>Welcome to the wis2box-webapp!</h2><br> This web-application allows you to configure datasets and stations, manually submit FM-12 SYNOP and check notifications sent by this wis2box.')

if (import.meta.env.VITE_WEBAPP_HOMEPAGE_MESSAGE != undefined) {
    homeContent.value = import.meta.env.VITE_WEBAPP_HOMEPAGE_MESSAGE;
}

const errorMessage = ref(null);

// check if current URL starts with VITE_BASE_URL
const baseUrl = import.meta.env.VITE_BASE_URL || '';
if (window.location.pathname.startsWith(baseUrl)) {
    // If it does do not show the error message
    errorMessage.value = null;
} else {
    // If it does not show the error message
    errorMessage.value = `Please access the web application via the base URL: ${baseUrl} to avoid CORS issues.`;
    console.error(errorMessage.value);
}

</script>

<style scoped></style>
