<template>
    <v-dialog v-model="dialog" max-width="800">
      <template #activator="{ props }">
        <v-btn
          color="#49C6E5"
          :block="block"
          append-icon="mdi-thermometer-lines"
          v-bind="props"
          @click="open"
        >Inspect TEMP</v-btn>
      </template>
      <v-card class="inspect-content">
        <v-btn
          icon="mdi-close"
          class="close-button"
          variant="plain"
          @click="dialog = false"
        />
        <v-card-title class="pad-filename">{{ fileName }}</v-card-title>
        <v-card-text>
          <v-alert
            v-if="error"
            type="error"
            dismissible
          >{{ error }}</v-alert>
          <v-data-table
            v-else
            :items="items"
            :headers="headers"
            items-per-page="25"
          />
        </v-card-text>
      </v-card>
    </v-dialog>
  </template>
  
  <script>
  import { defineComponent, ref } from 'vue';
  import {
    VDialog, VBtn, VCard, VCardTitle, VCardText,
    VDataTable, VAlert
  } from 'vuetify/lib/components';
  
  export default defineComponent({
    name: 'InspectBufrButton_TEMP',
    components: {
      VDialog, VBtn, VCard, VCardTitle, VCardText,
      VDataTable, VAlert
    },
    props: {
      fileUrl:    { type: String, required: false, default: '' },
      data:       { type: String, required: false, default: '' },
      fileName:   { type: String, required: true },
      block:      { type: Boolean, required: false, default: false }
    },
    setup(props) {
      const dialog  = ref(false);
      const items   = ref([]);
      const headers = ref([]);
      const error   = ref('');
  
      const load = async () => {
        const inputs = {};
        if (props.fileUrl) inputs.data_url = props.fileUrl;
        else if (props.data) inputs.data     = props.data;
        try {
          const resp = await fetch(
            `${import.meta.env.VITE_API_URL}/processes/bufr2temp/execution?f=json`,
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ inputs })
            }
          );
          const json = await resp.json();
          if (json.error) {
            error.value = json.error;
            return;
          }
          items.value   = json.items;
          
          headers.value = Object.keys(json.items[0] || {}).map(k => ({
            title: k, value: k, sortable: false
          }));
        } catch (e) {
          error.value = e.message;
        }
      };
  
      const open = async () => {
        await load();
        dialog.value = true;
      };
  
      return { dialog, items, headers, error, open };
    }
  });
  </script>
  
  <style scoped>
  .inspect-content { max-height: 80vh; }
  .close-button  { position: absolute; top: 8px; right: 8px; }
  .pad-filename  { padding: 16px; }
  </style>  
  