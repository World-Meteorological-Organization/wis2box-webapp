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
    <v-dialog v-model="showLoading" width="auto">
      <v-card>
        <v-card-text>Searching for station record on OSCAR/Surface</v-card-text>
        <v-progress-linear indeterminate rounded height="12" color="#004f9f">
        </v-progress-linear>
      </v-card>
    </v-dialog>
    <v-dialog v-model="showRedirect" width="auto">
      <v-card align="center">
        <v-card-text>{{ redirectMessage }}</v-card-text>
        <v-card-text color-text="warning">{{ redirectWarning }}</v-card-text>
        <v-card-actions align="center">
          <v-btn color="primary" @click='router.push("/station")' elevation=2>Cancel</v-btn>
          <v-btn color="warning" @click='router.push("/station/")' elevation=2>Create new station</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    <v-card max-width="1200px">
      <v-card-title class="big-title">Import station from OSCAR/Surface</v-card-title>
      <v-card-item>
        <v-form>
          <v-text-field :rules="[rules.validWSI]" v-model="wsi" label="WIGOS Station Identifier"
            hint="Enter WIGOS Station Identifier" persistent-hint @blur="trimWSI"/>
          <v-card-actions align="center">
            <v-btn @click="submit">Search</v-btn>
          </v-card-actions>
        </v-form>
      </v-card-item>
    </v-card>
    <v-card v-if="station && station._meta.ready" max-width="1200px">
      <v-form v-model="formValid" align="left">
        <v-card-item>
          <v-text-field label="Station name" v-model="station.properties.name" readonly :rules="[rules.validName]"
            hint="Enter name of station" persistent-hint>
          </v-text-field>
        </v-card-item>
        <v-card-item>
          <v-text-field label="WIGOS station identifier" v-model="station.properties.wigos_station_identifier" readonly
            :rules="[rules.validWSI]" hint="Enter the WIGOS station identifier" persistent-hint>
          </v-text-field>
        </v-card-item>
        <v-card-item>
          <v-text-field label="Traditional station identifier"
            v-model="station.properties.traditional_station_identifier"
            hint="Enter the traditional (5 or 7 digit) station identifier" persistent-hint>
          </v-text-field>
        </v-card-item>
        <v-card-item>
          <v-container>
            <v-row>
              <v-col cols="4">
                <v-row>
                  <v-text-field label="Longitude (decimal degrees E), -180 to 180" v-model="station.geometry.longitude"
                    :rules="[rules.validLongitude]" type="number" hint="Enter the station longitude (degrees E)"
                    persistent-hint />
                </v-row>
                <v-row>
                  <v-text-field label="Latitude (decimal degrees N), -90 to 90" v-model="station.geometry.latitude"
                    :rules="[rules.validLatitude]" type="number" hint="Enter the station latitude (degrees N)"
                    persistent-hint />
                </v-row>
                <v-row>
                  <v-text-field label="Station elevation above sea level (metres)" v-model="station.geometry.elevation"
                    :rules="[rules.validElevation]" type="number" hint="Station elevation above sea level (metres)"
                    persistent-hint />
                </v-row>
              </v-col>
              <v-col cols="8">
                <LocatorMap :longitude="parseFloat(station.geometry.longitude)"
                  :latitude="parseFloat(station.geometry.latitude)" />
              </v-col>
            </v-row>
          </v-container>
        </v-card-item>
        <v-card-item>
          <CodeListSelector codeList="facilityType" label="Facility type" defaultHint="Select facility type"
            v-model="station.properties.facility_type" />
        </v-card-item>
        <v-card-item>
          <v-text-field label="Barometer height above sea level" v-model="station.properties.barometer_height"
            :rules="[rules.validBarometerHeight]" hint="Enter barometer height (metres)" persistent-hint type="number">
          </v-text-field>
        </v-card-item>
        <v-card-item>
          <CodeListSelector codeList="WMORegion" label="WMO Region" defaultHint="Select WMO region"
            v-model="station.properties.wmo_region" />
        </v-card-item>
        <v-card-item>
          <CodeListSelector codeList="territory" label="Territory or WMO member operating the station"
            defaultHint="Select territory" v-model="station.properties.territory_name" />
        </v-card-item>
        <v-card-item>
          <CodeListSelector codeList="operatingStatus" label="Operating status" defaultHint="Select operating status"
            v-model="station.properties.status" />
        </v-card-item>
        <v-card-item>
          <TopicSelector v-model="station.properties.topics" multiple :rules="[rules.topic]" class="mt-2" />
        </v-card-item>
        <v-card-item>
          <v-text-field :rules="[rules.token]" type="password" autocomplete="one-time-code" clearable v-model="token"
            label='wis2box auth token for "collections/stations"'
            hint='Enter wis2box auth token for "collections/stations"' persistent-token></v-text-field>
        </v-card-item>
        <v-card-actions>
          <v-btn @click="confirm()" :disabled="!formValid" elevation=2>Save</v-btn>
          <v-btn @click="router.push('/station')" elevation=2>Cancel</v-btn>
        </v-card-actions>
      </v-form>
    </v-card>
  </v-sheet>
</template>
<script>
import { defineComponent, ref, onBeforeMount, watch } from "vue";
import { VSheet, VCard, VCardTitle, VCardItem, VForm, VTextField, VBtn, VCardActions, VProgressLinear } from 'vuetify/lib/components/index.mjs';
import { useRouter } from 'vue-router';
import TopicSelector from '@/components/stations/TopicSelector.vue';
import LocatorMap from '@/components/LocatorMap.vue';
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
  name: "ImportOSCAR",
  components: {
    VSheet, VCard, VCardTitle, VCardItem, VForm, VTextField, VBtn, VCardActions, LocatorMap,
    CodeListSelector, VProgressLinear, APIStatus, TopicSelector
  },
  setup() {
    const wsi = ref("");
    // this needs to be moved to a class / pinia model.
    const trimWSI = () => {
      wsi.value = wsi.value.trim();
    };
    const station = ref({
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
        facility_type: {},
        territory_name: {},
        barometer_height: null,
        wmo_region: {},
        url: null,
        topics: [],
        status: {},
        id: null  // WSI
      },
      _meta: {
        ready: false
      }
    });

    const errorMessage = ref(null);
    const showDialog = ref(false);
    const showLoading = ref(false);
    const redirectMessage = ref(null);
    const redirectWarning = ref(null);
    const showRedirect = ref(false);
    const token = ref(null);
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
    const data = ref(null);
    const router = useRouter();
    const formValid = ref(null);
    const territoryOptions = ref(null);
    const WMORegionOptions = ref(null);
    const facilityTypeOptions = ref(null);
    const operatingStatusOptions = ref(null);
    const selectedDataset = ref(null);

    onBeforeMount(async () => {
      territoryOptions.value = await loadCodeList('territory');
      facilityTypeOptions.value = await loadCodeList('facilityType');
      operatingStatusOptions.value = await loadCodeList('operatingStatus');
      WMORegionOptions.value = await loadCodeList('WMORegion');
    });

    const loadCodeList = async (codeList) => {
      let data;
      try {
        const clist = await fetch(`${import.meta.env.VITE_BASE_URL}/codelists/${codeList}.json`);
        if (clist.ok) {
          await clist.json().then((d) => data = d);
        } else {
          errorMessage.value = "HTTP error fetching code list, please see console.";
          console.log(clist);
          showDialog.value = true;
          showLoading.value = false;
        }
      } catch (error) {
        errorMessage.value = "HTTP error fetching code list, please see console.";
        showDialog.value = true;
        showLoading.value = false;
        console.log(error);
      }
      return data['@graph'].filter(item => item['@type'] === "skos:Concept");
    };


    const confirm = async () => {
      let apiURL = `${import.meta.env.VITE_API_URL}/collections/stations/items`;
      let leaf = "";
      apiURL = apiURL + leaf;
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

      try {
        const response = await fetch(apiURL, {
          method: 'POST',
          headers: {
            'encode': 'json',
            'Content-Type': 'application/geo+json',
            'Authorization': 'Bearer ' + token.value
          },
          body: JSON.stringify(record)
        });
        if (!response.ok) {
          console.log(record);
          if (response.status == 400) {
            errorMessage.value = "Station already imported, please edit via the station list"
          }
          else if (response.status == 401) {
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
          showLoading.value = false;
        } else {
          errorMessage.value = "Station successfully submitted, redirecting to station viewer.";
          showDialog.value = true;
          showLoading.value = false;
          setTimeout(() => { router.push("/station/" + wsi.value + "?action=view") }, 3000);
        }
      } catch (error) {
        errorMessage.value = "HTTP error posting to API, please see console.";
        showDialog.value = true;
        showLoading.value = false;
        console.log(record);
        console.log(error);
        console.log(apiURL);
      }
    };

    const submit = async () => {
      showLoading.value = true;
      let apiURL = `${import.meta.env.VITE_API_URL}/processes/oscar2feature/execution`;
      let payload = {
        "inputs": {
          "wigos_station_identifier": stripHTMLTags(wsi.value)
        }
      };
      // get data
      try {
        const response = await fetch(
          apiURL, {
          method: 'POST',
          headers: {
            'encode': 'json',
            'Content-Type': 'application/json',
            'authorization': 'Bearer ' + token.value
          },
          body: JSON.stringify(payload)
        }
        );
        if (!response.ok) {
          console.log(response);
          errorMessage.value = "Error fetching form OSCAR/Surface via WIS2box API, please check status of the API and OSCAR/Surface. See console for more details.";
          console.error(response.status);
          showDialog.value = true;
          showLoading.value = false;
        } else {
          data.value = await response.json();
        }
      } catch (error) {
        errorMessage.value = "Error fetching form OSCAR/Surface via WIS2box API, please check status of the API and OSCAR/Surface. See console for more details.";
        console.log(error);
        showDialog.value = true;
        showLoading.value = false;
      }
      if (data.value) {
        if (data.value.feature) {
          station.value.id = data.value.feature.id;
          station.value.type = data.value.feature.type;
          station.value.geometry.type = data.value.feature.geometry.type;
          station.value.geometry.coordinates = data.value.feature.geometry.coordinates;
          station.value.geometry.longitude = station.value.geometry.coordinates[0];
          station.value.geometry.latitude = station.value.geometry.coordinates[1];
          station.value.geometry.elevation = station.value.geometry.coordinates.length === 3 ?
            station.value.geometry.coordinates[2] : null;
          station.value.properties.name = data.value.feature.properties.name;
          station.value.properties.wigos_station_identifier = data.value.feature.properties.wigos_station_identifier;
          station.value.properties.traditional_station_identifier = data.value.feature.properties.traditional_station_identifier;
          station.value.properties.barometer_height = data.value.feature.properties.barometer_height;
          station.value.properties.url = data.value.feature.properties.url;
          station.value.properties.id = data.value.feature.properties.id;
          station.value.properties.facility_type = data.value.feature.properties.facility_type;
          station.value.properties.territory_name = data.value.feature.properties.territory_name;
          station.value.properties.wmo_region = data.value.feature.properties.wmo_region;
          station.value.properties.status = data.value.feature.properties.status;

          station.value._meta.ready = true;
          showLoading.value = false;
        } else if (data.value.error) {
          redirectMessage.value = "Station not found in OSCAR, unable to import." +
            " Please register station in OSCAR/Surface and try again.";

          redirectWarning.value = "For development and testing purposes stations can be created directly." +
            "To add a new station to the WIS2box please click the 'create new station' button";
          showRedirect.value = true;
          showLoading.value = false;
        } else {
          errorMessage.value = "Unexpected response, see logs for further details.";
          console.error("Error fetching station details:", data.value);
          showDialog.value = true;
          showLoading.value = false;
        }
      }
    };

    // Watchers
    watch(() => station.value.properties.wmo_region, (newValue) => {
      console.log(newValue);
    });

    return {
      wsi,
      errorMessage,
      showDialog,
      rules,
      router,
      station,
      formValid,
      confirm,
      showLoading,
      redirectMessage,
      redirectWarning,
      showRedirect,
      submit,
      token,
      selectedDataset,
      trimWSI
    };
  }
});
</script>
