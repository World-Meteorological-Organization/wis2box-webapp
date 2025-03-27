<template>
    <v-row class="justify-center">
        <v-card class="max-form-width">
            <v-card-item>
                <span v-html="homeContent"></span>
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
</script>

<style scoped></style>
