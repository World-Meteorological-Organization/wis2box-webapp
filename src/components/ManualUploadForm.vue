<template>
        <v-container class="max-form-width">
          <v-card-title class="big-title">Manual Data File Upload</v-card-title>
            <v-dialog v-model="showDialog" width="auto">
              <v-card>
                <v-card-text>{{msg}}</v-card-text>
                <v-card-actions>
                  <v-btn color="primary" block @click="showDialog = false">Close</v-btn>
                </v-card-actions>
              </v-card>
            </v-dialog>
            <v-card-text>
              
            </v-card-text>
            <v-stepper show-actions v-model="step">
                <v-stepper-header>
                    <v-stepper-item
                        :complete="status.fileLoaded"
                        title="Select file"
                        value="1" :color="step1Color">
                    </v-stepper-item>
                    <v-stepper-item
                        :complete="status.datasetIdentifier"
                        title="Select dataset"
                        value="2" :color="step2Color">
                    </v-stepper-item>
                    <v-stepper-item
                        :complete="status.password"
                        title="Authorize / publish"
                        value="3" :color="step3Color">
                    </v-stepper-item>
                    <v-stepper-item
                        :complete="step4Complete"
                        title="Review"
                        value="4" :color="step4Color">
                    </v-stepper-item>
                </v-stepper-header>
                <v-stepper-window>
                    <v-stepper-window-item value="1">
                        <v-card width="100%">
                            <v-card-title>Load data</v-card-title>
                            <v-card-text>
                                <v-file-input :rules="fileInputRules" label="Select file to upload" show-size v-model="incomingFile" variant="outlined"/>
                            </v-card-text>
                        </v-card>
                    </v-stepper-window-item>
                    <v-stepper-window-item value="2">
                        <v-card>
                            <v-card-title>Select dataset identifier</v-card-title>
                            <v-col cols="12">
                                <DatasetIdentifierSelector v-if="status.datasetLoad" :value="datasetSelected" @update:modelValue="newValue => datasetSelected = newValue" :key="datasetKey"/>
                            </v-col>
                            <v-checkbox v-model="status.datasetPlugin" label="Use dataset mappings" color="#" hide-details></v-checkbox>
                            <v-card-text v-if="!status.datasetPlugin">
                                <v-chip color="#64BF40" text-color="white">Universal plugin selected</v-chip>
                                <p>This form will use the universal plugin, uploading the file without data transformation. Please provide additional information required by the notification.</p>
                            </v-card-text>
                            <v-card-text v-if="status.datasetPlugin">
                                <v-chip color="#64BF40" text-color="white">Dataset mappings selected</v-chip>
                                <p>This form will use the pre-configured dataset mappings, uploading the file with data transformation from CSV or BUFR.</p>
                            </v-card-text>
                            <v-card-text v-if="!status.datasetPlugin">
                                <v-chip color="#A52A2A" text-color="black">Date is required.</v-chip>
                            </v-card-text>
                            <VueDatePicker v-if="!status.datasetPlugin" placeholder="Select Data Production Date in UTC" v-model="date"
                                :teleport="true" :start-time="startTime" time-picker-inline format="yyyy-MM-dd HH:mm" utc="preserve"/>
                                <div class="inspect-actions" v-if="status.stationIdentifier">
                                <v-card-text v-if="!status.datasetPlugin">
                            </v-card-text>
                            <StationIdentifierSelector v-if="!status.datasetPlugin" :value="stationSelected" @update:modelValue="newValue => stationSelected = newValue" :key="stationKey"/>                                      
                              </div>
                            <v-checkbox v-if="!status.datasetPlugin" v-model="status.stationIdentifier" label="Add station identifier" color="#" hide-details></v-checkbox>
                            </v-card>
                    </v-stepper-window-item>
                    <v-stepper-window-item value="3">
                        <v-card>
                            <v-card-title>Authorize and publish</v-card-title>
                            <v-card-text>
                              <v-text-field label="wis2box auth token for 'processes/wis2box'" v-model="token" rows="1"
                              :append-icon="showToken ? 'mdi-eye' : 'mdi-eye-off'" :type="showToken ? 'text' : 'password'" autocomplete="one-time-code"
                              @click:append="showToken = !showToken"
                              :rules="[v => !!v || 'Token is required']"
                              variant="outlined">
                            </v-text-field>
                            </v-card-text>
                            
                            <v-checkbox v-model="notificationsOnPending" label="Publish on WIS2" color="#" hide-details></v-checkbox>
                            <v-card-item v-if="token">Click next to submit the data</v-card-item>
                        </v-card>
                    </v-stepper-window-item>
                    <v-stepper-window-item value="4">
                      <v-row class="justify-center">
                        <v-col cols="12">
                          <!-- Output data -->
                          <v-card v-if="result">
                            <v-card-title>{{ resultTitle }}</v-card-title>

                            <v-list>

                              <v-list-item class="hint-default">
                                {{ numberNotifications }}</v-list-item>

                              <!-- WARNINGS -->
                              <!-- Warnings drop-down if there are any warnings -->
                              <v-list-group v-if="result.warnings && result.warnings.length > 0" ref="warningList" value="Warnings"
                                @click="scrollToRef('warningList')">
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
                              <v-list-group v-if="result.files && result.files.length > 0" ref="fileList" value="Files"
                                @click="scrollToRef('fileList')">
                                <template v-slot:activator="{ props }">
                                  <v-list-item v-bind="props" prepend-icon="mdi-check-circle">
                                    <template v-slot:prepend>
                                      <v-icon color="#00BD9D"></v-icon>
                                    </template>
                                    <!-- If number of BUFR files > 0, set text to green -->
                                    <span :style="{ color: '#00BD9D' }">Output files: {{ result.files.length }}</span>
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
                                          <DownloadButton :fileName="data_item.filename" :fileUrl="data_item.file_url" :block="true" />
                                          <div class="inspect-actions" v-if="status.datasetPlugin">
                                          <InspectBufrButton :fileName="data_item.filename" :fileUrl="data_item.file_url" :block="true" />
                                          </div>
                                        </div>
                                        <div class="file-actions" v-if="data_item.data">
                                          <DownloadButton :fileName="data_item.filename" :data="data_item.data" :block="true" />
                                          <div class="inspect-actions" v-if="status.datasetPlugin">
                                          <InspectBufrButton :fileName="data_item.filename" :data="data_item.data" :block="true" />
                                            </div>
                                        </div>
                                      </div>
                                      <!-- For narrow windows, make buttons less wide -->
                                      <div class="hidden-lg-and-up">
                                        <div class="file-actions" v-if="data_item.file_url">
                                          <DownloadButton :fileName="data_item.filename" :fileUrl="data_item.file_url" :block="false" />
                                          <div class="inspect-actions" v-if="status.datasetPlugin">
                                          <InspectBufrButton :fileName="data_item.filename" :fileUrl="data_item.file_url" :block="false" />
                                          </div>
                                        </div>
                                        <div class="file-actions" v-if="data_item.data">
                                          <DownloadButton :fileName="data_item.filename" :data="data_item.data" :block="false" />
                                          <div class="inspect-actions" v-if="status.datasetPlugin">
                                          <InspectBufrButton :fileName="data_item.filename" :data="data_item.data" :block="false" />
                                          </div>
                                        </div>
                                      </div>
                                  </div>
                                  <v-divider v-if="index < result.files.length - 1" class="divider-spacing"></v-divider>
                                </v-list-item>
                              </v-list-group>

                              <!-- BUFR files drop-down if there are no warnings -->
                              <v-list-item v-else prepend-icon="mdi-check-circle">
                                <span>Output files: 0</span>
                              </v-list-item>

                            </v-list>
                          </v-card>
                        </v-col>
                      </v-row>
                    </v-stepper-window-item>
                </v-stepper-window>
                <v-stepper-actions
                    @click:prev="prev"
                    @click:next="next"
                    >
                </v-stepper-actions>
            </v-stepper>
        </v-container>
</template>

<script>
    import { defineComponent, nextTick, ref, onMounted, watch, computed} from 'vue';
    import { VFileInput, VCardActions, VBtn, VCard, VCardText, VCardItem, VChip, VTooltip } from 'vuetify/lib/components/index.mjs';
    import { VList, VListItem, VContainer, VCardTitle, VIcon, VDialog} from 'vuetify/lib/components/index.mjs';
    import { VDataTable} from 'vuetify/lib/components/index.mjs';
    import { VStepper, VStepperHeader, VStepperItem, VStepperWindow, VStepperWindowItem, VStepperActions} from 'vuetify/lib/components/index.mjs';
    import InspectBufrButton from '@/components/InspectBufrButton.vue';
    import DownloadButton from '@/components/DownloadButton.vue';
    import DatasetIdentifierSelector from '@/components/DatasetIdentifierSelector.vue';
    import StationIdentifierSelector from '@/components/StationIdentifierSelector.vue';

    export default defineComponent({
        name: 'ManualUploadForm',
        components: {
            VFileInput, VCardActions, VBtn, VCard, VCardText, VCardItem, VDataTable,
            VChip, VTooltip, VListItem, VList, VContainer,
            VCardTitle, VIcon, VStepper, VStepperHeader, VStepperItem, VStepperWindow, VStepperWindowItem,
            VStepperActions, VDialog, InspectBufrButton, DownloadButton,
            DatasetIdentifierSelector, StationIdentifierSelector
        },
        
        setup() {
            // reactive variables
            const theData = ref(null);
            const headers = ref(null);
            const incomingFile = ref(null);
            const step=ref(0);

            const status = ref({
                fileLoaded: false,
                fileSized:false,
                datasetPlugin: true,
                datasetLoad: true,
                fileValidated: false,
                datasetIdentifier: false,
                stationIdentifier: true,
                password: false
            });
            // Variable to control whether token is seen or not
            const showToken = ref(false);
            const token = ref(null);
            const datasetSelected = ref(null);
            const stationSelected = ref(null);
            const rawData = ref(null);
            const plugin = ref(null);
            const date = ref(null);
            const msg = ref(null);
            const showDialog = ref(null);
            const scrollRef = ref(null);
            const result = ref(null);
            const notificationsOnPending = ref(false);
            
            // Keys tp force reload components
            let stationKey = 0;
            let datasetKey = 0;

            //constants
            const startTime = ref({ hours: 0, minutes: 0 });
            
            // computed properties

            

            const step1Color = computed(() => {
                if (status.value.fileLoaded) {
                    return "#64BF40"
                }
                return "#003DA5"
            })
            const step2Color = computed(() => {
                if (status.value.datasetIdentifier) {
                    return "#64BF40"
                }
                return "#003DA5"
            })
            const step3Color = computed(() => {
                if (status.value.password) {
                    return "#64BF40"
                }
                return "#003DA5"
            })
            const step4Complete = computed(() => {
                return status.value.fileLoaded && status.value.datasetIdentifier && status.value.password && status.value.submitted;
            })
            const step4Color = computed(() => {
                if (step4Complete.value) {
                    return "#64BF40"
                }
                return "#003DA5"
            })

            const resultTitle = computed( () => {
                if( result.value && result.value.result){
                  return "Result: " + result.value.result;
                }
                return "Unknown";
            });
            const numberNotifications = computed( () => {
                let messagesPublished = 0;
                if( result.value ){
                  messagesPublished = result.value['messages published'];
                }
                return "WIS2 notifications published: " + messagesPublished;
            });
            // life cycle hooks
            onMounted( () => {
                setTimeout(scrollToRef(200));
            });

            const forceDatasetSelectorRerender = async () => {
              // Remove DatasetSelector from the DOM
              status.value.datasetLoad = false;

                // Wait for the change to get flushed to the DOM
                await nextTick();

                // Add the component back in
              status.value.datasetLoad = true;
            };

            const scrollToRef = () => {
              if (scrollRef.value) {
                scrollRef.value.scrollIntoView({ behavior: 'smooth' });
              }
            };

            const loadData = async() => {
                if( incomingFile.value ){
                    // now load the data file
                    let reader = new FileReader();
                    
                    reader.readAsArrayBuffer(incomingFile.value);
                    reader.onload = async () => {
                        // load the data                        
                        rawData.value = reader.result;

                    };

                }
            };
            const submit = async() => {
                FileUpload();
                status.value.submitted = true;
            };
            function _arrayBufferToBase64( buffer ) {
              var binary = '';
              var bytes = new Uint8Array( buffer );
              var len = bytes.byteLength;
              for (var i = 0; i < len; i++) {
                  binary += String.fromCharCode( bytes[ i ] );
              }
              return window.btoa( binary );
          }
            const FileUpload = async() => {
              
              let payload = {
                    inputs: {
                        data: _arrayBufferToBase64(rawData.value),
                        channel: datasetSelected.value.metadata.topic,
                        metadata_id: datasetSelected.value.metadata.id,
                        notify: notificationsOnPending.value,
  
                    }
                };
              if(plugin.value["plugin"] === "wis2box.data.universal_data.UniversalData"){
                payload = {
                    inputs: {
                        data: _arrayBufferToBase64(rawData.value),
                        channel: datasetSelected.value.metadata.topic,
                        metadata_id: datasetSelected.value.metadata.id,
                        notify: notificationsOnPending.value,
                        filename: incomingFile.value.name,
                        datetime: date.value,
                        is_binary: true
                    }
                };
                if( !(stationSelected.value === null)){
                  payload.inputs.wigos_station_identifier = stationSelected.value.id;
                }
            }
              else if(plugin.value["plugin"] === "wis2box.data.csv2bufr.ObservationDataCSV2BUFR")
              {
                payload = {
                  inputs: {
                      data: new TextDecoder().decode(rawData.value),
                      channel: datasetSelected.value.metadata.topic,
                      metadata_id: datasetSelected.value.metadata.id,
                      notify: notificationsOnPending.value,
                      template: plugin.value["template"],
                  }
                };
              }
              
            let apiURL = `${import.meta.env.VITE_API_URL}/processes/wis2box-bufr2bufr/execution`;
              if(plugin.value["plugin"] === "wis2box.data.csv2bufr.ObservationDataCSV2BUFR") {
                apiURL = `${import.meta.env.VITE_API_URL}/processes/wis2box-csv2bufr/execution`;
              }
              else if (plugin.value["plugin"] === "wis2box.data.universal_data.UniversalData"){
                apiURL = `${import.meta.env.VITE_API_URL}/processes/wis2box-publish_data/execution`;
              }
              
                const response = await fetch(apiURL, {
                method: 'POST',
                headers: {
                    'encode': 'json',
                    'Content-Type': 'application/geo+json',
                    'Authorization': 'Bearer '+ token.value
                },
                body: JSON.stringify(payload)
              });
              // showDialog.value = true;
              // msg.value = JSON.stringify(payload);

              if (!response.ok) {
                if (response.status == 401) {
                  msg.value = "Unauthorized, please provide a valid 'processes/wis2box' token"
                }
                else if (response.status == 404) {
                  msg.value = "Error submitting data: API not found"
                }
                else if (response.status == 500) {
                  msg.value = "Error submitting data: Internal server error"
                }
                else {
                  msg.value = "API Error, please check the console";
                  console.error('HTTP error', response.status);
                }
                
                showDialog.value = true;
                result.value = {
                  "result": "API error",
                  "errors": [
                    apiURL + " returned " + response.status
                  ]
                };
                
              } else {
                
                const data = await response.json();
                result.value = data;
                result.value.files = [];
                for( let item in result.value.data_items){
                  result.value.files.push( result.value.data_items[item].file_url);
                }
              }
            }
            const prev = () => {
                switch (step.value){
                  // case 1:
                  //   incomingFile.value = null;
                  //   rawData.value = null;
                  //   status.value.fileLoaded = false;
                  //   status.value.fileSized = false;
                  case 2:
                    datasetSelected.value = null;
                    stationSelected.value = null;
                    stationKey += 1
                    plugin.value = null;
                    date.value = null;
                    status.value.datasetIdentifier = false;
                    status.value.datasetPlugin = true;
                    forceDatasetSelectorRerender();
                 }
                 step.value = step.value === 0 ? 0 : step.value - 1;
            };
            const next = () => {
                let proceed = false;
                switch (step.value){
                  case 0:
                    if( status.value.fileLoaded){
                      if( !status.value.fileSized ){
                        showDialog.value = true;
                        msg.value = "File size must be less than 1MB";
                      }
                      else{
                      datasetSelected.value = null;
                      stationSelected.value = null;
                      stationKey += 1
                      plugin.value = null;
                      date.value = null;
                      status.value.datasetIdentifier = false;
                      status.value.datasetPlugin = true;
                      forceDatasetSelectorRerender();
                      proceed = true;
                      loadData()}
                    }else{
                      showDialog.value = true;
                      msg.value = "Please select or drag and drop a file to upload";
                    }
                    break;

                  case 1:
                    if( status.value.datasetIdentifier ){
                      if(!status.value.datasetPlugin){
                        if(!status.value.stationIdentifier)
                      {
                        stationSelected.value = null;
                      }
                        if(date.value === null){
                          showDialog.value = true;
                          msg.value = "Please enter the required observation date before proceeding.";
                        }
                        else{
                          proceed = true;
                        }   
                    }
                    else{
                      let filetype = incomingFile.value.name.split('.').pop();
                      let keys="";
                      let foundMapping = false;
                      for ( let map in datasetSelected.value.mappings ){
                        
                        keys += map + ", ";
                        
                        if(map === filetype)
                      {
                          foundMapping = true;
                          if( datasetSelected.value.mappings[map][0].plugin === "wis2box.data.csv2bufr.ObservationDataCSV2BUFR" || datasetSelected.value.mappings[map][0].plugin === "wis2box.data.bufr4.ObservationDataBUFR" ){
                            plugin.value = datasetSelected.value.mappings[map][0];   
                            proceed = true;
                          }
                          else if( datasetSelected.value.mappings[map][0].plugin === "wis2box.data.synop2bufr.ObservationDataSYNOP2BUFR" ){
                            showDialog.value = true;
                            msg.value = "File type " + filetype + " uses a mapping from SYNOP to BUFR, please use the 'SYNOP to BUFR' form instead.";
                          }
                          else{
                            showDialog.value = true;
                            msg.value = "File type " + filetype + " does not have a mapping from CSV or BUFR.";
                          }
                          
                        }
                      }
                      if( !foundMapping ){
                        showDialog.value = true;
                        msg.value = "No mapping found for file type " + filetype + " in the following keys: " + keys.slice(0, -2);
                      }
                    }

                    }
                    else{
                      showDialog.value = true;
                      msg.value = "Please select a dataset to publish on before proceeding.";
                    }
                    break;
                  case 2:
                    
                    if(!status.value.datasetPlugin ){
                      if( !status.value.password  ){
                        showDialog.value = true;
                        msg.value = "Please enter the authorization token before proceeding.";
                      }
                      else{
                        plugin.value = {
                          plugin: "wis2box.data.universal_data.UniversalData",
                          key: "universal_data",
                          
                        };
                        submit();
                        proceed = true;
                      }
                    }
                    else{
                      if( status.value.password ){
                        submit();
                        proceed = true;                     
                    }    
                    else{
                      showDialog.value = true;
                      msg.value = "Please enter the authorization token before proceeding.";
                    }}
                    break;
                }
                if( proceed ){
                  step.value = step.value === 3 ? 3 : step.value + 1;
                }
            };

            // Watchers
            watch( datasetSelected, (val) => {
              status.value.datasetIdentifier = !!val;
            });

            watch( incomingFile, (val) => {
              status.value.fileLoaded = !!val;
              status.value.fileSized = val.size < 1024*1024;
            });

            watch( token, () => {
              if( token.value && token.value.length > 0 ){
                status.value.password = true;
              }else{
                status.value.password = false;
              }
            });

            return {theData, headers, incomingFile, startTime, date, loadData, step, prev, next, scrollToRef,
                     status, showToken, token, notificationsOnPending, step1Color, step2Color, step3Color, step4Complete, step4Color,
                    datasetSelected, stationSelected, submit, msg, showDialog, result, resultTitle, numberNotifications};
        },
    })
</script>
