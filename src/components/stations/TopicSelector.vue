<template>
    <div v-if="!errorMessage">
      <v-select v-if="(options !== null)" :items="options" item-title="topic" item-value="topic" :label="label"
        v-model="selected" :readonly="readonly" :rules="rules"
        :hint="selected ? selected.description : 'Select topic'" persistent-hint :multiple="multiple"
        return-object variant="outlined" />
    </div>
    <div v-else class="error">
      <v-text-field class="text-error" readonly>{{ errorMessage }}</v-text-field>
    </div>
  </template>
  
  <script>
  import { defineComponent, ref, computed, onBeforeMount, watch } from 'vue';
  import { VSelect, VTextField } from 'vuetify/lib/components/index.mjs';
  
  
  export default defineComponent({
    name: 'TopicSelector',
    components: {
      VSelect, VTextField
    },
    props: {
      modelValue: {},
      readonly: {
        type: Boolean,
        default: false
      },
      multiple: {
        type: Boolean,
        default: false
      },
      rules: {
        type: Array
      }
    },
    emits: ["update:modelValue"],
    setup(props, { emit }) {
      // Static variables
      const testMode = import.meta.env.VITE_TEST_MODE === "true" || import.meta.env.VITE_API_URL == undefined;
  
      // Reactive variables
      const apiUrl = `${import.meta.env.VITE_API_URL}/collections/discovery-metadata/items?f=json`;
      const options = ref(null);
      const selected = ref([]);
      const errorMessage = ref(null);
  
      // Computed
      const label = computed(() => {
        let label = "Topic";
        if (props.multiple) {
          label += "s";
        }
        return label;
      });

      const fetchOptions = async () => {
        // Get dataset IDs
        if (testMode) {
          // If test mode enabled, show test IDs
          console.log("TEST_MODE is enabled");
          options.value = [
            {
              topic: "origin/a/wis2/test1-centre/core/test1",
              description: "Test 1 description"
            },
            {
              topic: "origin/a/wis2/test2-centre/core/test2",
              description: "Test 2 description"
            },
          ]
  
        }
        else {
          try {
            const response = await fetch(apiUrl);
            if (!response.ok) {
              throw new Error(`HTTP error! Status: ${response.status}`);
            }
            else {
              const data = await response.json();
              if (data.features) {
                // Use Array.map to create a new array of the dataset IDs
                options.value = data.features.map(feature => {
                  if (feature.properties) {
                    return {
                      topic: feature.properties['wmo:topicHierarchy'],
                      description: feature.properties['description']
                    }
                  }
                });
              }
              else {
                console.error("API response is not an object");
              }
            }
          }
          catch (error) {
            errorMessage.value = "Error fetching dataset identifiers, please check the API end point." +
              " See logs for more information.";
            console.error("Error fetching dataset identifiers:", error)
          }
        }
      };
  
  
      onBeforeMount(async () => {
        let m = false;
        await fetchOptions();
        if (props.modelValue && props.modelValue.length) {
          for (const topic of props.modelValue) {
            const option = options.value.find(option => option.topic === topic);
            if (option) {
              m = true;
              selected.value.push(option);
            }
          }
        }
        if (m) {
          emit("update:modelValue", selected.value);
        }
      });
  
      watch(() => props.modelValue, (newValue) => {
        selected.value = newValue;
      });
  
      watch(() => selected.value, (newValue) => {
        if (selected.value) {
          emit("update:modelValue", newValue);
        }
      });
  
      return { label, selected, options, errorMessage };
    }
  });
  </script>
  