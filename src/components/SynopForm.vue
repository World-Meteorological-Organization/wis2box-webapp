<template>
    <v-row class="justify-center">
        <v-col cols="12" class="max-form-width">
            <!-- Form entry --><v-fade-transition appear>
                <v-card>
                    <!-- Font size of title for tablets and desktops -->
                    <v-card-title class="big-title">Submit FM 12–XIV Ext. SYNOP Bulletin</v-card-title>
                    <v-card-text>See the WMO <a href="https://library.wmo.int/idviewer/35713/33">Manual on Codes, Volume I.1</a>, for a description of the FM 12-XIV Ext. SYNOP format</v-card-text>
                    <v-card-item>
                        <v-container>
                            <v-form>
                                <!-- Date selection -->
                                <v-row>
                                    <v-col cols="2">
                                        <VueDatePicker v-model="date" :teleport="true" :state="datePossible"
                                            month-picker auto-apply required />
                                        <p v-if="datePossible === false" class="hint-text hint-invalid">Date in the
                                            future: please choose a
                                            valid
                                            month and year in UTC
                                        </p>
                                        <p v-else-if="datePossible === true" class="hint-text hint-valid">Date in UTC
                                            valid</p>
                                        <p v-else class="hint-text hint-default">Month and year in UTC</p>
                                    </v-col>
                                </v-row>
                                <!-- FM 12 data entry -->
                                <v-row>
                                    <v-col cols="12">
                                        <v-textarea label="FM 12" v-model.lazy="bulletin" @change="checkMessage"
                                            variant="outlined"></v-textarea>
                                        <p v-if="aaxxPresent == false" class="hint-text hint-invalid">AAXX must be
                                            present for a valid SYNOP
                                            message
                                        </p>
                                        <p v-else-if="equalsPresent == false" class="hint-text hint-invalid">Delimiter
                                            (=) must be present at
                                            the
                                            end
                                            of each SYNOP report</p>
                                        <p v-else class="hint-text hint-default">Raw FM 12 bulletin</p>
                                    </v-col>
                                </v-row>

                                <!-- Dataset identifier selection -->
                                <v-row>
                                    <v-col cols="12">
                                        <DatasetIdentifierSelector v-model="datasetSelected"></DatasetIdentifierSelector>
                                    </v-col>
                                </v-row>


                                <!-- Execution token -->
                                <v-row>
                                    <v-divider class="mb-5"/>
                                    <v-col cols="12">
                                        <v-text-field label="wis2box auth token for 'processes/wis2box'" v-model="token"
                                            rows="1" :append-icon="showToken ? 'mdi-eye' : 'mdi-eye-off'"
                                            :type="showToken ? 'text' : 'password'"
                                            autocomplete="one-time-code"
                                            @click:append="showToken = !showToken"
                                            :rules="[v => !!v || 'Token is required']"
                                            variant="outlined" />
                                    </v-col>
                                </v-row>
                            </v-form>
                            <v-row class="button-align" no-gutters>
                                <v-col cols="2">
                                    <v-btn block color="#003DA5" :disabled="submitDisabled" append-icon="mdi-cloud-upload"
                                        :loading="loading" @click="submit">Submit
                                        <template v-slot:loader>
                                            <v-progress-linear indeterminate></v-progress-linear>
                                        </template>
                                    </v-btn>
                                </v-col>
                                <v-col cols="2">
                                    <v-checkbox :disabled="submitDisabled" v-model="notificationsOnPending"
                                        label="Publish on WIS2" hide-details></v-checkbox>
                                </v-col>
                                <v-col cols="2">
                                    <v-checkbox v-model="addGTSHeaders"
                                        label="Add GTS headers" hide-details></v-checkbox>
                                </v-col>
                            </v-row>
                            <v-row v-if="addGTSHeaders" class="mt-2">
                                <v-col cols="3">
                                    <v-text-field
                                        label="TTAAii"
                                        v-model="TTAAii"
                                        variant="outlined"
                                        :rules="[TTAAiiRule]"
                                        @input="e => capitalizeInput(e, 'TTAAii')"
                                    ></v-text-field>
                                </v-col>
                                <v-col cols="3">
                                    <v-text-field
                                        label="CCCC"
                                        v-model="cccc"
                                        variant="outlined"
                                        :rules="[CCCCRule]"
                                        @input="e => capitalizeInput(e, 'cccc')"
                                    ></v-text-field>
                                </v-col>
                            </v-row>
                        </v-container>
                    </v-card-item>

                </v-card>
            </v-fade-transition>
        </v-col>
    </v-row>

    <v-row class="justify-center">
        <v-col cols="12" class="max-form-width">
            <!-- Output data -->
            <v-card v-if="result">
                <v-card-title>{{ resultTitle }}</v-card-title>

                <v-list>

                    <v-list-item class="hint-default">
                        {{ numberNotifications }}</v-list-item>

                    <!-- WARNINGS -->
                    <!-- Warnings drop-down if there are any warnings -->
                    <v-list-group v-if="result.warnings && result.warnings.length > 0" ref="warningList"
                        value="Warnings" @click="scrollToRef('warningList')">
                        <template v-slot:activator="{ props }">
                            <v-list-item v-bind="props" prepend-icon="mdi-alert-circle">
                                <template v-slot:prepend>
                                    <v-icon color="#FD9235"></v-icon>
                                </template>
                                <!-- If number of warnings > 0, set text to orange -->
                                <span class="warning-color">Warnings: {{ result.warnings.length }}</span>
                            </v-list-item>
                        </template>

                        <v-list-item v-for="(warning, index) in result.warnings" :key="index" class="warning-item">
                            {{ warning }}
                        </v-list-item>
                    </v-list-group>

                    <!-- Warnings drop-down if there are no warnings -->
                    <v-list-item v-else prepend-icon="mdi-alert-circle">
                        <span>Warnings: 0</span>
                    </v-list-item>


                    <!-- ERRORS -->
                    <!-- Errors drop-down if there are any errors -->
                    <v-list-group v-if="result.errors && result.errors.length > 0" ref="errorList" value="Errors"
                        @click="scrollToRef('errorList')">
                        <template v-slot:activator="{ props }">
                            <v-list-item v-bind="props" prepend-icon="mdi-close-circle">
                                <template v-slot:prepend>
                                    <v-icon color="#EA4848"></v-icon>
                                </template>
                                <!-- If number of errors > 0, set text to red -->
                                <span class="error-color">Errors: {{ result.errors.length }}</span>
                            </v-list-item>
                        </template>

                        <v-list-item v-for="(error, index) in result.errors" :key="index" class="error-item">
                            {{ error }}
                        </v-list-item>
                    </v-list-group>

                    <!-- Errors drop-down if there are no warnings -->
                    <v-list-item v-else prepend-icon="mdi-close-circle">
                        <span>Errors: 0</span>
                    </v-list-item>


                    <!-- OUTPUT BUFR -->
                    <!-- BUFR files drop-down if there are any output files -->
                    <v-list-group v-if="result.data_items && result.data_items.length > 0" ref="fileList" value="Files"
                        @click="scrollToRef('fileList')">
                        <template v-slot:activator="{ props }">
                            <v-list-item v-bind="props" prepend-icon="mdi-check-circle">
                                <template v-slot:prepend>
                                    <v-icon color="#00BD9D"></v-icon>
                                </template>
                                <!-- If number of BUFR files > 0, set text to green -->
                                <span :style="{ color: '#00BD9D' }">Output BUFR files: {{ result.data_items.length
                                    }}</span>
                            </v-list-item>

                        </template>
                        <v-list-item v-for="(data_item, index) in result.data_items" :key="index">
                            <div class="file-actions">
                                <div>
                                    {{ data_item.filename }}
                                </div>
                                <!-- For wider windows, make buttons wider -->
                                <div class="hidden-md-and-down">
                                    <div class="file-actions" v-if="data_item.file_url">
                                        <DownloadButton :fileName="data_item.filename" :fileUrl="data_item.file_url"
                                            :block="true" />
                                        <InspectBufrButton :fileName="data_item.filename" :fileUrl="data_item.file_url"
                                            :block="true" />
                                    </div>
                                    <div class="file-actions" v-if="data_item.data">
                                        <DownloadButton :fileName="data_item.filename" :data="data_item.data"
                                            :block="true" />
                                        <InspectBufrButton :fileName="data_item.filename" :data="data_item.data"
                                            :block="true" />
                                    </div>
                                </div>
                                <!-- For narrow windows, make buttons less wide -->
                                <div class="hidden-lg-and-up">
                                    <div class="file-actions" v-if="data_item.file_url">
                                        <DownloadButton :fileName="data_item.filename" :fileUrl="data_item.file_url"
                                            :block="false" />
                                        <InspectBufrButton :fileName="data_item.filename" :fileUrl="data_item.file_url"
                                            :block="false" />
                                    </div>
                                    <div class="file-actions" v-if="data_item.data">
                                        <DownloadButton :fileName="data_item.filename" :data="data_item.data"
                                            :block="false" />
                                        <InspectBufrButton :fileName="data_item.filename" :data="data_item.data"
                                            :block="false" />
                                    </div>
                                </div>
                            </div>
                            <v-divider v-if="index < result.data_items.length - 1" class="divider-spacing"></v-divider>
                        </v-list-item>
                    </v-list-group>

                    <!-- BUFR files drop-down if there are no warnings -->
                    <v-list-item v-else prepend-icon="mdi-check-circle">
                        <span>Output BUFR files: 0</span>
                    </v-list-item>

                </v-list>
            </v-card>
        </v-col>
    </v-row>
</template>

<script>
import { defineComponent, ref, computed, watch } from 'vue';
import { VCard, VCardTitle, VCardItem, VForm, VTextarea, VBtn, VListGroup } from 'vuetify/lib/components/index.mjs';
import DatasetIdentifierSelector from '@/components/DatasetIdentifierSelector.vue';
import InspectBufrButton from '@/components/InspectBufrButton.vue';
import DownloadButton from '@/components/DownloadButton.vue';

export default defineComponent({
    name: 'SynopForm',
    components: {
        VCard,
        VCardTitle,
        VCardItem,
        VTextarea,
        VForm,
        VBtn,
        VListGroup,
        DatasetIdentifierSelector,
        InspectBufrButton,
        DownloadButton
    },
    setup() {
        // Reactive variables

        // GTS headers logic
        const addGTSHeaders = ref(false);
        const TTAAii = ref("");
        const cccc = ref("");

        // Current month/year to compare against user selection
        const date = ref({
            month: new Date().getUTCMonth(),
            year: new Date().getUTCFullYear()
        });
        // Verifies entered date is not in the future
        const datePossible = ref(null);
        // FM 12 data
        const bulletin = ref(null);
        // Boolean to check if AAXX is in bulletin
        const aaxxPresent = ref(true);
        // Boolean to check if = delimiter is in bulletin
        const equalsPresent = ref(true);
        // Dataset selected by user
        const datasetSelected = ref(null);
        // Execution token to be entered by user
        const token = ref(null);
        // Variable to control whether token is seen or not
        const showToken = ref(false);
        // Realtime variable for if user has selected notifications or not
        const notificationsOnPending = ref(true);
        // Variable that updates to the pending variable when the user has submitted
        const notificationsOn = ref(true);
        // Boolean for the loading animation
        const loading = ref(false);
        // JSON object for the concatenated user inputs
        const input = ref(null);
        // Output from synop2bufr call
        const result = ref(null);
        // Lists for warnings, errors and files used for scroll into view later
        const warningList = ref(null)
        const errorList = ref(null)
        const fileList = ref(null)

        // Computed values

        // Boolean for whether the submit button is disabled or not
        const submitDisabled = computed(() => {
            // Basic checks
            let disabled = (datePossible.value === false) || !bulletin.value || !aaxxPresent.value || !equalsPresent.value || !datasetSelected.value || !token.value;
            // If GTS headers are enabled, validate TTAAii and CCCC
            if (addGTSHeaders.value) {
                // Require both fields to be non-empty and valid
                if (!TTAAii.value || !cccc.value || TTAAiiRule(TTAAii.value) !== true || CCCCRule(cccc.value) !== true) {
                    disabled = true;
                }
            }
            return disabled;
        })

        // Computes the result title re: success, partial success, or failure
        const resultTitle = computed(() => {
            if (result.value?.result) {
                const resultKey = result.value.result;
                return "Result: " + resultKey;
            }
            return "Unknown";
        });

        // Computes how many WIS2 notifications were made, depending on
        // whether the user has selected the notification toggle or not
        const numberNotifications = computed(() => {
            let messagesPublished;
            if (result.value && notificationsOn.value === true) {
                messagesPublished = result.value["messages published"];
            } else {
                messagesPublished = 0;
            }
            return "WIS2 notifications published: " + messagesPublished;
        });

        // Methods

        // Check if AAXX and = delimiter present in the FM 12 data entered
        const checkMessage = () => {
            aaxxPresent.value = bulletin.value.includes('AAXX ');
            // Remove trailing newline characters and 'nnnn'/'NNNN'
            // from bulletin before checking if the report ends in '='
            const trimmedBulletin = bulletin.value.replace(/(nnnn|\n)+$/i, "");
            const lastChar = trimmedBulletin.charAt(trimmedBulletin.length - 1);
            equalsPresent.value = lastChar.includes('=')
        }

        // When the user clicks on one of the expandable lists such as
        // the output BUFR files, this method force scrolls the page down
        // so that the content is not accidentally missed by the user
        const scrollToRef = (refName) => {
            setTimeout(() => {
                if (refName === 'warningList' && warningList.value) {
                    warningList.value.$el.scrollIntoView({ behavior: 'smooth' });
                }
                else if (refName === 'errorList' && errorList.value) {
                    errorList.value.$el.scrollIntoView({ behavior: 'smooth' });
                }
                else if (refName === 'fileList' && fileList.value) {
                    fileList.value.$el.scrollIntoView({ behavior: 'smooth' });
                }
            }, 200); // 200ms delay to allow the list to render before scrolling
        }

        // Simulated output response in test environment representing a success
        const testSuccessResult = () => {
            const testData = {
                "result": "Success",
                "messages transformed": 2,
                "messages published": 2,
                "data_items": [
                    {
                        "file_url": "http://3.127.235.197/data/2023-01-19/wis/synop/test/WIGOS_0-20000-0-64400_20230119T060000.bufr4",
                        "filename": "WIGOS_0-20000-0-64400_20230119T060000.bufr4"
                    },
                    {
                        "data": "QlVGUgABgAQAABYAAAAAAAAAAAJuHgAH5wETBgAAAAALAAABgMGWx2AAAVMABOIAAANjQ0MDAAAAAAAAAAAAAAAIDIGxoaGBgAAAAAAAAAAAAAAAAAAAAPzimYBA/78kmTlBBU//////////////////////////////+dUnxn1P///////////26vbYOl////////////////////////////////////////////////////////////////AR////gJH///+T/x/+R/yf////////////7///v9f/////////////////////////////////+J/b/gAff2/4Dz/X/////////////////////////////////////7+kAH//v6QANnH////////////9+j//////////////v0f//////f//+/R/+////////////////////fo//////////////////3+oAP///////////////////8A3Nzc3",
                        "filename": "WIGOS_0-20000-0-64400_20230119T060000.bufr4"
                    }
                ],
                "warnings": [],
                "errors": []
            }
            // Update the result variable with the test data
            result.value = testData;
        }

        // Simulated output response in test environment
        // representing a partial success
        const testPartialSuccessResult = () => {
            const testData = {
                "result": "Partial Success",
                "messages transformed": 2,
                "messages published": 1,
                "data_items": [
                    {
                        "file_url": "http://3.127.235.197/data/2023-01-19/wis/synop/test/WIGOS_0-20000-0-64400_20230119T060000.bufr4",
                        "filename": "WIGOS_0-20000-0-64400_20230119T060000.bufr4"
                    },
                    {
                        "data": "QlVGUgABgAQAABYAAAAAAAAAAAJuHgAH5wETBgAAAAALAAABgMGWx2AAAVMABOIAAANjQ0MDAAAAAAAAAAAAAAAIDIGxoaGBgAAAAAAAAAAAAAAAAAAAAPzimYBA/78kmTlBBU//////////////////////////////+dUnxn1P///////////26vbYOl////////////////////////////////////////////////////////////////AR////gJH///+T/x/+R/yf////////////7///v9f/////////////////////////////////+J/b/gAff2/4Dz/X/////////////////////////////////////7+kAH//v6QANnH////////////9+j//////////////v0f//////f//+/R/+////////////////////fo//////////////////3+oAP///////////////////8A3Nzc3",
                        "filename": "WIGOS_0-20000-0-64400_20230119T060000.bufr4"
                    }
                ],
                "warnings": [
                    "Missing station height for station 15090",
                    "Station 15108 not found in station metadata list",
                ],
                "errors": []
            };
            // Update the result variable with the test data
            result.value = testData;
        }

        // Simulated output response in test environment representing a failure
        const testFailureResult = () => {
            const testData = {
                "result": "Failure",
                "messages transformed": 0,
                "messages published": 0,
                "data_items": [],
                "warnings": [],
                "errors": [
                    "No data returned for WSI=0-20000-0-15001 and timestamp=20230919132400",
                    "No data returned for WSI=0-20000-0-15002 and timestamp=20230919132400"
                ]
            };
            // Update the result variable with the test data
            result.value = testData;
        }

        // Pushing the user input to the synop2bufr process
        const callSynop2Bufr = async () => {
            let payload = {
                inputs: {
                    data: bulletin.value, // Raw FM 12 data
                    year: date.value.year, // Year of data
                    month: date.value.month + 1, // Month of data, +1 as JS starts
                    // from 0 for months
                    channel: datasetSelected.value.metadata.topic, // Topic hierarchy
                    metadata_id: datasetSelected.value.metadata.id, // Dataset identifier
                    notify: notificationsOn.value // Boolean for WIS2 notifications
                }
            };
            // Add GTS headers if enabled
            if (addGTSHeaders.value) {
                payload.inputs.gts_ttaaii = TTAAii.value;
                payload.inputs.gts_cccc = cccc.value;
            }
            let headers = {
                'encode': 'json',
                'Content-Type': 'application/geo+json',
                'authorization': 'Bearer ' + token.value
            };

            const synopUrl = `${import.meta.env.VITE_API_URL}/processes/wis2box-synop2bufr/execution`

            const response = await fetch(synopUrl, {
                method: 'POST',
                headers: headers,
                body: JSON.stringify(payload)
            });

            if (!response.ok) {
                let res;
                if (response.status == 401) {
                    res = "Unauthorized, please provide a valid 'processes/wis2box' token"
                }
                else if (response.status == 404) {
                    res = "Error submitting data: API not found"
                }
                else if (response.status == 500) {
                    res = "Error submitting data: Internal server error"
                }
                else {
                    res = "API Error, please check the console";
                }
                console.error('HTTP error', response.status);
                result.value = {
                    "result": res,
                    "errors": [
                        synopUrl + " returned " + response.status
                    ]
                };
            } else {
                const data = await response.json();
                result.value = data;
            }
        }

        // Method for when the user presses the submit button,
        // including a loading animation and obtaining the result
        const submit = async () => {
            // Start loading animation
            loading.value = true;

            // Set result back to null
            result.value = null;

            // Update whether the user wants WIS2 notifications
            notificationsOn.value = notificationsOnPending.value;

            // Check if bulletin contains the word success, failure or partial success
            if (bulletin.value.includes("success")) {
                testSuccessResult();
            } else if (bulletin.value.includes("partial")) {
                testPartialSuccessResult();
            } else if (bulletin.value.includes("failure")) {
                testFailureResult();
            } else {
                // Otherwise, call the synop2bufr process
                await callSynop2Bufr();
            }

            await new Promise(r => setTimeout(r, 200)) // Artificial delay to test loading

            // End loading animation
            loading.value = false;
        }

        // Watches
        watch(date, (newVal) => {
            if (newVal) {
                // newVal-month and newVal-year are in UTC, construct a new Date object
                // with the same month and year but in local time
                const dateInLocalTime = new Date(Date.UTC(newVal.year, newVal.month));
                // Check if the date is not in the future
                datePossible.value = dateInLocalTime <= new Date();
            } else {
                datePossible.value = null;
            }
        }, { deep: true });

        // TTAAii must be exactly 4 latin characters followed by 2 digits
        const TTAAiiRule = v => {
            if (!v) return true;
            return /^[a-zA-Z]{4}\d{2}$/.test(v) || 'TTAAii must be 4 letters followed by 2 digits';
        };

        // CCCC must be exactly 4 alphanumeric characters
        const CCCCRule = v => {
            if (!v) return true;
            return /^[a-zA-Z0-9]{4}$/.test(v) || 'CCCC must be 4 characters';
        };

        // Auto-capitalize input for TTAAii and CCCC fields
        const capitalizeInput = (e, field) => {
            let val = '';
            if (typeof e === 'string') {
                val = e.toUpperCase();
            } else if (e && e.target && typeof e.target.value === 'string') {
                val = e.target.value.toUpperCase();
            }
            if (field === 'TTAAii') {
                TTAAii.value = val;
            } else if (field === 'cccc') {
                cccc.value = val;
            }
        };

        return {
            date,
            datePossible,
            bulletin,
            aaxxPresent,
            equalsPresent,
            datasetSelected,
            token,
            showToken,
            notificationsOnPending,
            notificationsOn,
            loading,
            input,
            result,
            warningList,
            errorList,
            fileList,
            submitDisabled,
            resultTitle,
            numberNotifications,
            checkMessage,
            scrollToRef,
            submit,
            addGTSHeaders,
            TTAAii,
            cccc,
            TTAAiiRule,
            CCCCRule,
            capitalizeInput,
        }
    }
})
</script>

<style scoped>
.calendar-box {
    width: 250px;
}

.button-align {
    display: flex;
    align-items: center;
}
</style>
