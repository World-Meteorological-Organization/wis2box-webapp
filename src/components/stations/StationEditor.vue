<template>
  <v-sheet align="center">
    <APIStatus />
    <v-dialog v-model="showDialog" width="auto">
      <v-card>
        <v-card-text>{{ errorMessage }}</v-card-text>
        <v-card-actions>
          <v-btn color="primary" block @click="showDialog = false">Close</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    <v-card-title v-if="!readonly">{{ route.params.id ? 'Edit' : 'Create new' }} station</v-card-title>
    <v-card-title v-else>View station</v-card-title>
    <v-card v-if="station" max-width="1200px">
      <v-form v-model="formValid" align="left">
        <v-container class="pa-5">
          <v-text-field label="Station name" v-model="station.properties.name" :rules="[rules.validName]"
            :readonly="readonly || route.params.id.length > 0" hint="Enter name of station" persistent-hint
            variant="outlined" class="my-5">
          </v-text-field>
          <v-text-field label="WIGOS station identifier" v-model="station.properties.wigos_station_identifier"
            :rules="[rules.validWSI]" :readonly="readonly || route.params.id.length > 0"
            hint="Enter the WIGOS station identifier" persistent-hint variant="outlined" class="my-5">
          </v-text-field>
          <v-text-field label="Traditional station identifier"
            v-model="station.properties.traditional_station_identifier" :readonly="readonly"
            hint="Enter the traditional station identifier (ASCII or numeric characters only)" persistent-hint
            variant="outlined" class="my-5">
          </v-text-field>
          <v-container>
            <v-row>
              <v-col cols="4">
                <v-row>
                  <v-text-field label="Longitude (decimal degrees E), -180 to 180" v-model="station.geometry.longitude"
                    :rules="[rules.validLongitude]" :readonly="readonly" type="number"
                    hint="Enter the station longitude (degrees E)" persistent-hint variant="outlined" class="my-5" />
                </v-row>
                <v-row>
                  <v-text-field label="Latitude (decimal degrees N), -90 to 90" v-model="station.geometry.latitude"
                    :rules="[rules.validLatitude]" :readonly="readonly" type="number"
                    hint="Enter the station latitude (degrees N)" persistent-hint variant="outlined" class="my-5" />
                </v-row>
                <v-row>
                  <v-text-field label="Station elevation above sea level (metres)" v-model="station.geometry.elevation"
                    :rules="[rules.validElevation]" :readonly="readonly" type="number"
                    hint="Station elevation above sea level (metres)" persistent-hint variant="outlined" class="my-5" />
                </v-row>
              </v-col>
              <v-col cols="8">
                <LocatorMap :longitude="parseFloat(station.geometry.longitude)"
                  :latitude="parseFloat(station.geometry.latitude)" variant="outlined" />
              </v-col>
            </v-row>
          </v-container>
          <CodeListSelector :readonly="readonly" codeList="facilityType" label="Facility type"
            defaultHint="Select facility type" v-model="station.properties.facility_type" class="my-5" />
          <v-text-field label="Barometer height above sea level" v-model="station.properties.barometer_height"
            :rules="[rules.validBarometerHeight]" :readonly="readonly" hint="Enter barometer height (metres)"
            persistent-hint type="number" variant="outlined" class="my-5">
          </v-text-field>
          <CodeListSelector :readonly="readonly" codeList="WMORegion" label="WMO Region" defaultHint="Select WMO region"
            v-model="station.properties.wmo_region" />
          <CodeListSelector :readonly="readonly" codeList="territory"
            label="Territory or WMO member operating the station" defaultHint="Select territory"
            v-model="station.properties.territory_name" />
          <CodeListSelector :readonly="readonly" codeList="operatingStatus" label="Operating status"
            defaultHint="Select operating status" v-model="station.properties.status" />
          <TopicSelector v-model="station.properties.topics" multiple :readonly="readonly"
            :rules="[rules.topic]" class="mt-2" />
          <v-divider />
          <v-text-field :rules="[rules.token]" type="password" autocomplete="one-time-code" clearable v-model="token"
            label='wis2box auth token for "collections/stations"'
            hint='Enter wis2box auth token for "collections/stations"' persistent-token variant="outlined"
            class="my-5"></v-text-field>
          <v-card-actions v-if="!readonly">
            <v-btn @click="registerStation()" elevation=2 :disabled="!formValid">Save</v-btn>
            <v-btn @click="cancelEdit()" elevation=2>Cancel</v-btn>
          </v-card-actions>
          <v-card-actions v-else>
            <v-btn @click="router.push('/station/' + route.params.id + '?action=edit')" elevation=2>Edit</v-btn>
          </v-card-actions>
        </v-container>
      </v-form>
    </v-card>
  </v-sheet>
</template>
<script>
import { defineComponent, ref, watch, onBeforeMount, onMounted } from 'vue';
import { VCard, VTextField, VContainer, VRow, VBtn, VCardActions, VForm } from 'vuetify/lib/components/index.mjs';
import TopicSelector from '@/components/stations/TopicSelector.vue';
import LocatorMap from '@/components/LocatorMap.vue';
import { useRoute, useRouter } from 'vue-router';
import CodeListSelector from '@/components/CodeListSelector.vue';
import APIStatus from '@/components/APIStatus.vue';

function stripHTMLTags(input) {
  if (input == null) {
    return null;
  }
  if (typeof input !== 'string') {
    console.warn("Invalid input passed to stripHTMLTags, empty string returned")
    return '';
  }
  const tag_regex = /<\/?[a-zA-Z]+\/?>/g;
  const escapes = /[\x00-\x1F\x7F;\\]/g;
  return input.replace(tag_regex, '').replace(escapes, '');
}

export default defineComponent({
  name: 'StationEditor',
  components: {
    VContainer, VRow, VCard, VTextField, APIStatus,
    TopicSelector, VBtn, VCardActions, LocatorMap, VForm, CodeListSelector
  },
  setup() {
    // Reactive variables
    const route = useRoute();
    const router = useRouter();
    const station = ref(null);
    const topics = ref([null]);
    const showDialog = ref(false);
    const errorMessage = ref(null);
    const readonly = ref(false);
    const msg = ref('');
    const token = ref(null);
    const formValid = ref(null);
    const selectedDataset = ref(null);

    // Define validation rules
    const rules = ref({
      validWSI: value => /^0-[0-9]{1,5}-[0-9]{0,5}-[0-9a-zA-Z]{1,16}$/.test(value) || 'Invalid WSI',
      validTSI: value => value && value.length > 0 ? true : 'TSI must be set',
      validLongitude: value => !(Math.abs(value) > 180 || isNaN(value)) ? true : 'Invalid longitude',
      validLatitude: value => value && !(Math.abs(value) > 90 || isNaN(value)) ? true : 'Invalid latitude',
      validElevation: value => value && !isNaN(value) ? true : 'Invalid elevation',
      validBarometerHeight: value => value && !isNaN(value) ? true : 'Invalid barometer height',
      validName: value => value && value.length > 0 ? true : 'Name must be set',
      token: value => value && value.length > 0 ? true : 'Please enter the authorization token',
      topic: value => value.length > 0 ? true : 'Select at least one topic'
    });

    // Methods

    const cancelEdit = async () => {
      readonly.value = true;
      if (route.params.id) {
        loadStation(route.params.id);
        router.push('/station/' + route.params.id);
      } else {
        router.push('/station');
      }
    };

    const registerStation = async () => {
      if (!formValid.value) {
        errorMessage.value = "Please correct validation errors before submitting"
        showDialog.value = true;
        return;
      }
      let record = {
        id: stripHTMLTags(station.value.properties.wigos_station_identifier),  // WSI
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [parseFloat(station.value.geometry.longitude),
          parseFloat(station.value.geometry.latitude),
          parseFloat(station.value.geometry.elevation)]
        },
        properties: {
          name: stripHTMLTags(station.value.properties.name),
          wigos_station_identifier: stripHTMLTags(station.value.properties.wigos_station_identifier),  // WSI
          traditional_station_identifier: stripHTMLTags(station.value.properties.traditional_station_identifier),
          facility_type: station.value.properties.facility_type['skos:notation'] ?? null,
          territory_name: station.value.properties.territory_name['skos:notation'] ?? null,
          barometer_height: parseFloat(station.value.properties.barometer_height),
          wmo_region: station.value.properties.wmo_region['skos:notation'] ?? null,
          url: "https://oscar.wmo.int/surface/#/search/station/stationReportDetails/" +
            stripHTMLTags(station.value.properties.wigos_station_identifier),
          topics: station.value.properties.topics.map((selected) => (selected.topic)),
          status: station.value.properties.status['skos:notation'] ?? null,
          id: stripHTMLTags(station.value.properties.wigos_station_identifier)  // WSI
        }
      }
      let apiURL = `${import.meta.env.VITE_API_URL}/collections/stations/items`;
      let leaf = route.params.id ? "/" + route.params.id : "";
      apiURL = apiURL + leaf;
      const response = await fetch(apiURL, {
        method: route.params.id ? 'PUT' : 'POST',
        headers: {
          'encode': 'json',
          'Content-Type': 'application/geo+json',
          'authorization': 'Bearer ' + token.value
        },
        body: JSON.stringify(record)
      });
      if (!response.ok) {
        console.log(record);
        if (response.status == 401) {
          errorMessage.value = "Unauthorized, please provide a valid 'collections/stations' token"
        }
        else if (response.status == 404) {
          errorMessage.value = "Error submitting record, API not found"
        }
        else if (response.status == 500) {
          errorMessage.value = "Error submitting record, internal server error"
        }
        else {
          errorMessage.value = "Error submitting record, please check the console";
          console.error('HTTP error', response.status);
        }
        showDialog.value = true;
      } else {
        errorMessage.value = "Station successfully submitted, redirecting to station list.";
        showDialog.value = true;
        setTimeout(() => { router.push("/station") }, 3000); // short pause to give backend time to catch up.
      }
    };

    // Mounted methods
    onBeforeMount(async () => {
      if (route.query.action === "edit") {
        readonly.value = false;
      } else {
        readonly.value = true;
      }
    });


    onMounted(async () => {
      // load codes lists
      if (route.params.id) {
        await loadStation(route.params.id);
      }
      if (!station.value) {
        readonly.value = false;
        station.value = {
          id: null,  // WSI
          type: 'Feature',
          geometry: {
            type: 'Point',
            coordinates: [null, null, null]
          },
          properties: {
            name: null,
            wigos_station_identifier: null,  // WSI
            traditional_station_identifier: null,
            facility_type: null,
            territory_name: null,
            barometer_height: null,
            wmo_region: null,
            url: null,
            topics: [],
            status: null,
            id: null  // WSI
          }
        };
      }
    })

    // load station
    const loadStation = async (wsi) => {
      const apiURL = `${import.meta.env.VITE_API_URL}/collections/stations/items/${wsi}`;
      try {
        const response = await fetch(apiURL);
        if (!response.ok && response.status !== 404) {
          throw new Error(`HTTP error! Status: ${response.status}`);
        } else if (response.status === 404) {
          errorMessage.value = "Station not found, please check the ID or register a new station."
          showDialog.value = true;
          router.push('/station/');
        } else {
          let data = await response.json();
          station.value = {
            id: data.id,  // WSI
            type: data.type,
            geometry: {
              type: data.geometry.type,
              coordinates: data.geometry.coordinates,
              longitude: data.geometry.coordinates[0],
              latitude: data.geometry.coordinates[1],
              elevation: data.geometry.coordinates[2]
            },
            properties: {
              name: data.properties.name,
              wigos_station_identifier: data.properties.wigos_station_identifier,  // WSI
              traditional_station_identifier: data.properties.traditional_station_identifier,
              facility_type: data.properties.facility_type,
              territory_name: data.properties.territory_name,
              barometer_height: data.properties.barometer_height,
              wmo_region: data.properties.wmo_region,
              url: data.properties.url,
              topics: data.properties.topics,
              status: data.properties.status,
              id: data.properties.id  // WSI
            }
          };
        }
      }
      catch (error) {
        errorMessage.value = "Error fetching station details, please check the API end point." +
          " See logs for more information.";
        console.error("Error fetching station details:", error)
      }
    }

    // Watchers
    watch((route), () => {
      if (route.query.action === "edit") {
        readonly.value = false;
      } else {
        readonly.value = true;
      }
    })

    return {
      station,
      topics,
      registerStation,
      showDialog,
      msg,
      rules,
      route,
      router,
      readonly,
      errorMessage,
      token,
      formValid,
      cancelEdit,
      selectedDataset
    };
  }
});
</script>
