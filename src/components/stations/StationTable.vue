<template>
  <APIStatus/>
  <v-row class="justify-center">
    <v-col cols="12" class="max-dashboard-width">
      <v-card>
        <v-card-title class="big-title">Stations</v-card-title>
        <v-card-item v-if="items">
          <VTextField style="width: 400px;" v-model="search" prepend-icon="mdi-text-search" label="Search" single-line hide-details variant="outlined"></VTextField>
          <VDataTable :headers="headers" :items="items" :search="search" dense small>
              <template v-slot:item.actions="{ item }">
                <v-icon size="small" @click="editRecord(item)">mdi-pen</v-icon>
                <v-icon size="small" @click="viewRecord(item)">mdi-eye</v-icon>
                <v-icon size="small" @click="deleteRecord(item)">mdi-delete</v-icon>
              </template>
              <template v-slot:item.url="{ item }">
                <a :href="item.url">
                  {{ item.url }}
                </a>
              </template>
              <template v-slot:top>
                <v-dialog v-model="deleteDialog" width="auto" persistent>
                  <v-card>
                    <v-card-text>Please type the WIGOS station identifier to confirm the deletion</v-card-text>
                    <v-card-item><v-text-field v-model="stationToDelete" label="Station to delete"></v-text-field></v-card-item>
                    <v-card-item><v-text-field type="password" autocomplete="one-time-code" clearable v-model="token" label="Auth token"></v-text-field></v-card-item>
                    <v-card-actions>
                      <v-btn
                          color="error"
                          @click="confirmDelete( {item} )"
                          v-if="selectedStation===stationToDelete && token">Confirm deletion</v-btn>
                      <v-btn color="success" @click="closeDeleteDialog()">Cancel</v-btn>
                    </v-card-actions>
                  </v-card>
                </v-dialog>
              </template>
          </VDataTable>
        </v-card-item>
        <v-card-item>
          <v-btn prepend-icon="mdi-plus" color="success" @click="addRecord()">Add new station</v-btn>
        </v-card-item>
      </v-card>
    </v-col>
  </v-row>

</template>

<script>
import { defineComponent, ref, onMounted } from 'vue';
import { VCard, VCardTitle, VCardText, VTextField, VDataTable } from 'vuetify/lib/components/index.mjs';
import { useRouter } from 'vue-router';
import APIStatus from '@/components/APIStatus.vue';


export default defineComponent({
  name: 'StationTable',
  components: {
    VCard,
    VCardTitle,
    VCardText,
    VDataTable,
    VTextField,
    APIStatus
  },
  setup() {
    const headers = ref([]);
    const search = ref("");
    const sortBy = ref([{key:"", order:"desc"}]);
    const items = ref([]);
    const errorMessage = ref(null);
    const deleteDialog = ref(false);
    const stationToDelete = ref(null);
    const selectedStation = ref(null);
    const router = useRouter();
    const token = ref(null);

    const loadStations = async () => {
        items.value = null;
        const apiURL = `${import.meta.env.VITE_API_URL}/collections/stations/items?f=json&limit=2000`;
        try {
          let response = await fetch(apiURL);
          if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
          }else{
            let featureCollection = await response.json();
            console.log("featureCollection", featureCollection);
            items.value = featureCollection.features.map( (feature) => {
              return{
                actions: "actions",
                id: feature.id,
                station_name: feature.properties.name,
                wigos_station_identifier: feature.properties.wigos_station_identifier,
                traditional_station_identifier: feature.properties.traditional_station_identifier,
                facility_type: feature.properties.facility_type,
                latitude: feature.geometry ? feature.geometry.coordinates[1] : null,
                longitude: feature.geometry ? feature.geometry.coordinates[0] : null,
                elevation: feature.geometry ? feature.geometry.coordinates[2] : null,
                barometer_height: feature.properties.barometer_height,
                territory_name: feature.properties.territory_name,
                wmo_region: feature.properties.wmo_region,
                url: feature.properties.url,
                topics: feature.properties.topics ? JSON.stringify(feature.properties.topics) : JSON.stringify([feature.properties.topic]),
                status: feature.properties.status
                }
            });
          }
        }
        catch (error) {
          errorMessage.value = "Error fetching topic hierarchy, please check the API end point." +
                                " See logs for more information.";
          console.error("Error fetching topic hierarchy:", error)
        }
        if( items.value && items.value.length > 0){
          headers.value = Object.keys(items.value[0]).map( key => ({
            title: key,
            value: key,
            key: key,
            sortable: true
          }));
        };
    }

    onMounted( async() => {
      loadStations();
    });

    const closeDeleteDialog = () => {
      selectedStation.value = null;
      stationToDelete.value = null;
      deleteDialog.value = false;
      // reload the stations
      loadStations();
    };
    const confirmDelete = async () => {
      if( selectedStation.value === stationToDelete.value ){
        const apiURL = `${import.meta.env.VITE_API_URL}/collections/stations/items/${stationToDelete.value}`;
        try{
          let response = await fetch(apiURL, {
              method: 'DELETE',
              headers: {
                  'encode': 'json',
                  'Content-Type': 'application/geo+json',
                  'authorization': 'Bearer ' + token.value
              },
              body: null
            });
          if (!response.ok) {
            console.error('HTTP error', response.status);
          }else {
            setTimeout(2000); // short pause to give backend time to catch up.
            closeDeleteDialog();
          }
        }
        catch (error) {
          errorMessage.value = "Error deleting record, see logs for more information.";
          console.error(error);
        }
      }
    };
    const deleteRecord = (id) => {
      selectedStation.value = id.id;
      deleteDialog.value = true;
    };

    const editRecord = (id) => {
      router.push("/station/"+id.id+"?action=edit")
    }

    const viewRecord = (id) => {
      router.push("/station/"+id.id)
    }

    const addRecord = () => {
      router.push("/import-station")
    }

    return {headers, items, search, sortBy, confirmDelete, addRecord, deleteRecord, closeDeleteDialog,
            stationToDelete, selectedStation, deleteDialog, editRecord, viewRecord, token};
  }

});
</script>
