<template>
    <v-row class="justify-center">
        <v-col cols="12" class="max-dashboard-width">
            <v-card-title class="big-title">WIS2 Notifications Monitoring Dashboard</v-card-title>

            <v-card-item>
                <!-- Drop down selection for the dataset ID the user wants to monitor -->
                <v-row class="mt-2">
                    <v-col cols="10">
                        <DatasetIdentifierSelector v-model="selectedDatasetTemp" class="mb-3"></DatasetIdentifierSelector>
                    </v-col>
                </v-row>
                <!-- Remaining selections: datetime range, WSI, and limit -->
                <v-row class="my-0">
                    <v-col>
                        <v-row>
                            <v-col cols="5">
                                <VueDatePicker v-model="selectedDateRangeTemp" range multi-calendars time-picker-inline
                                    required :teleport="true" placeholder="Datetime range" format="yyyy/MM/dd HH:mm" />
                                <p class="hint-text hint-default">Choose the datetime range for the notifications (default: previous 24
                                    hours)</p>
                            </v-col>


                            <v-col cols="3">
                                <!-- Search bar to search for a WSI and only monitor that station -->
                                <v-text-field v-model="searchedWsiTemp" label="WSI"
                                    hint="Search a WMO Station Identifier (optional)" persistent-hint variant="outlined"></v-text-field>
                            </v-col>

                            <!-- Limit for how many notifications to display (default = 100) -->
                            <v-col cols="2">
                                <v-select v-model="selectedLimitTemp" :items="limits" hint="Limit" persistent-hint variant="outlined"></v-select>
                            </v-col>


                            <!-- Monitor button, that is only clickable when topic and date range selected -->
                            <v-col cols="2">
                                <v-btn color="#003DA5" class="update-button" size="x-large" block append-icon="mdi-database-search"
                                    :disabled="updateDisabled" @click="handleUpdate">Update</v-btn>
                            </v-col>
                        </v-row>
                    </v-col>
                </v-row>
            </v-card-item>
        </v-col>

        <v-col cols="12" class="max-dashboard-width">
            <v-divider :thickness="2" />
        </v-col>

        <v-col cols="12" class="max-dashboard-width">
            <!-- Dashboard visualising the notifications of the topic selected -->
            <!-- A key is needed to ensure this dashboard updates when the props are changed -->
            <NotificationDashboard :datasetID="selectedDataset.metadata.id" :startDate="selectedStartDate" :datasetTopic="selectedDataset.metadata.topic"
                :endDate="selectedEndDate" :wsi="searchedWsi" :limit="selectedLimit" v-if="showDashboard"
                :key="dashboardKey" class="my-4" />
        </v-col>
    </v-row>
</template>
  
<script>
import { defineComponent, ref, computed } from 'vue';
import { VCardTitle } from 'vuetify/lib/components/index.mjs';
import VueDatePicker from '@vuepic/vue-datepicker';
import '@vuepic/vue-datepicker/dist/main.css';
import DatasetIdentifierSelector from '@/components/DatasetIdentifierSelector.vue';
import NotificationDashboard from '@/components/monitoring/NotificationDashboard.vue';

export default defineComponent({
    name: 'MonitoringPage',
    components: {
        VCardTitle,
        VueDatePicker,
        DatasetIdentifierSelector,
        NotificationDashboard
    },
    setup() {
        // Static variables
        const testMode = import.meta.env.VITE_TEST_MODE === "true" || import.meta.env.VITE_API_URL == undefined;
        const now = new Date();
        const twentyFourHoursAgo = new Date(now.getTime() - 86400000);

        // Reactive variables

        // For each prop, we have a temporary and a final version.
        // The temporary version is what the user selects before clicking update
        // The final version is what has been selected when clicking update

        // Topic selected by the user, used to get the topic hierarchy
        // from the topics array
        const selectedDatasetTemp = ref(null);
        const selectedDataset = ref(null);
        // Date range for notifications, defaults to [24 hours from now, now]
        const selectedDateRangeTemp = ref([twentyFourHoursAgo, now]);
        const selectedStartDate = ref(twentyFourHoursAgo);
        const selectedEndDate = ref(now);
        // WSI searched by the user
        const searchedWsiTemp = ref(null);
        const searchedWsi = ref(null);
        // Array of limits for user to select
        const limits = ref([10, 50, 100, 500, 1000]);
        // Limits optionally configured by user, defaults to 100
        const selectedLimitTemp = ref(100);
        const selectedLimit = ref(100);
        // Boolean to show the notification dashboard
        // Key to make sure dashboard always updates when the update button is pressed
        const showDashboard = ref(false);
        const dashboardKey = ref(0);

        // Computed

        // Boolean for whether the monitor button is disabled or not
        const updateDisabled = computed(() => {
            return !selectedDatasetTemp.value || !selectedDateRangeTemp.value || (selectedDateRangeTemp.value.length !== 2)
        })

        // Methods

        // Method to update the props and display the notificaiton dashboard when the 
        // user clicks on the monitor button
        const handleUpdate = () => {
            // Update props
            selectedDataset.value = selectedDatasetTemp.value;
            selectedStartDate.value = new Date(selectedDateRangeTemp.value[0]);
            selectedEndDate.value = new Date(selectedDateRangeTemp.value[1]);
            searchedWsi.value = searchedWsiTemp.value;
            selectedLimit.value = selectedLimitTemp.value;
            // Add 1 to the key so that the dashboard is forced to update
            dashboardKey.value++
            // Display dashboard
            showDashboard.value = true;
            // Log in test mode
            if (testMode) {
                console.log('TEST_MODE is enabled')
                console.log('Sent start time:', selectedStartDate.value.toISOString())
                console.log('Sent end time:', selectedEndDate.value.toISOString())
            }
        }

        return {
            selectedDatasetTemp,
            selectedDataset,
            selectedDateRangeTemp,
            selectedStartDate,
            selectedEndDate,
            searchedWsiTemp,
            searchedWsi,
            limits,
            selectedLimitTemp,
            selectedLimit,
            showDashboard,
            dashboardKey,
            updateDisabled,
            handleUpdate
        }
    }
});
</script>
  
<style scoped>

.update-button {
    margin-left: -3px;
}
</style>