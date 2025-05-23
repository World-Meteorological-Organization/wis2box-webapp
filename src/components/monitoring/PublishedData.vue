<template>
  <v-card>
    <v-card-title class="text-left">
      Published Data
    </v-card-title>
    <!-- Limit the size of the list and add scroll feature -->
    <v-card-text>
      <v-text-field v-model="fileSearch" placeholder="Search for a file..." clearable variant="outlined" />
    </v-card-text>
    <div class="scrollable-file-list">
      <template v-for="(file, index) in filteredFiles" :key="index">
        <v-list class="file-list">
          <v-row justify="center" align="center">
            <v-col cols="5">

              <!-- Display the timestamp -->
              <div class="secondary">
                {{ formatTime(filteredPublishTimes[index]) }} UTC
              </div>

              <!-- Display the file name -->
              <div class="url-font">
                {{ getFileName(file.url) }}
              </div>
            </v-col>

            <v-divider vertical class="mr-5"/>

            <v-col cols="3">
              <DownloadButton :fileName="getFileName(file.url)" :fileUrl="file.url" :block="true" />
            </v-col>

            <v-col cols="3">
              <InspectBufrButton_TEMP v-if="file.type === 'application/bufr' && file.url.includes('temp/')"
              :fileUrl="file.url" :block="true" />
              <InspectBufrButton v-else-if="file.type === 'application/bufr'" :fileName="getFileName(file.url)"
                :fileUrl="file.url" :block="true" />
              <InspectAlertButton v-else-if="fileIsCAP(file)" :fileUrl="file.url" :fileName="getFileName(file.url)" :block="true" />
            </v-col>
          </v-row>
        </v-list>
        <v-divider />
      </template>
    </div>
  </v-card>
</template>

<script>
import { defineComponent, ref, computed } from 'vue';
import { VCard, VCardTitle } from 'vuetify/lib/components/index.mjs';
import DownloadButton from '@/components/DownloadButton.vue';
import InspectBufrButton from '@/components/InspectBufrButton.vue';
import InspectBufrButton_TEMP from '@/components/InspectBufrButton_TEMP.vue';
import InspectAlertButton from '@/components/monitoring/InspectAlertButton.vue';

export default defineComponent({
  name: 'PublishedData',
  props: {
    messages: {
      type: Array,
      required: true,
      default: () => []
    }
  },
  components: {
    VCard,
    VCardTitle,
    DownloadButton,
    InspectBufrButton,
    InspectAlertButton
  },
  setup(props) {

    // Reactive variables

    // The string searched by the user
    const fileSearch = ref(null)

    // Computed

    // Filter the files in published data by the search parameter
    const filteredFiles = computed(() => {
      // Create array of objects with url and type from the messages
      let fileObjects = props.messages.map(message => ({
        url: message.canonical_url,
        type: message.type
      }));

      if (fileSearch.value) {
        return fileObjects.filter(file => getFileName(file.url).includes(fileSearch.value));
      }
      return fileObjects;
    });

    // Filter the associated publish times by the search parameter
    const filteredPublishTimes = computed(() => {
      // Create array of file urls and publish times from the messages
      let fileUrls = props.messages.map(message => message.canonical_url);
      let publishTimes = props.messages.map(message => new Date(message.pubtime));

      if (fileSearch.value) {
        return publishTimes.filter((_, index) => getFileName(fileUrls[index]).includes(fileSearch.value));
      }
      return publishTimes;
    });

    // Methods

    const fileIsCAP = (file) => {
      return file.type === 'application/octet-stream' &&
         file.url.endsWith('.xml') &&
         file.url.includes('cap');
    };

    // Method to get filename from the canonical href
    const getFileName = (url) => {
      const urlParts = url.split('/');
      return urlParts[urlParts.length - 1];
    };

    // Shows the UTC publish time in a more readable format
    const formatTime = (timestamp) => {
      const year = timestamp.getUTCFullYear();
      const month = String(timestamp.getUTCMonth() + 1).padStart(2, '0');
      const day = String(timestamp.getUTCDate()).padStart(2, '0');
      const hours = String(timestamp.getUTCHours()).padStart(2, '0');
      const minutes = String(timestamp.getUTCMinutes()).padStart(2, '0');
      return `${year}/${month}/${day} ${hours}:${minutes}`;
    };

    return {
      fileSearch,
      filteredFiles,
      filteredPublishTimes,
      getFileName,
      formatTime,
      fileIsCAP
    }
  }
})
</script>

<style scoped>
.scrollable-file-list {
  max-height: 500px;
  overflow-y: auto;
}

.file-list {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
}

.file-container {
  display: flex;
  flex-direction: column;
  margin-left: 1rem;
}

.button-container {
  display: flex;
  gap: 50px;
  flex-grow: 1;
  margin-right: 1rem;
}

.button {
  flex-grow: 1;
  min-width: 100px;
}

.url-font {
  font-size: 18px;
}
</style>
