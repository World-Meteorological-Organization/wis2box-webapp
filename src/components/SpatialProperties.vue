<template>
    <v-row dense>
        <v-col cols="12" md="5">
            <v-card class="pa-3">
                <v-row dense>
                    <v-col cols="4">
                        <v-select
                            label="Bounding box"
                            :items="boundingBoxOptions"
                            item-title="title"
                            item-value="value"
                            v-model="selectedBoundingBoxIndex"
                            variant="outlined"
                        ></v-select>
                    </v-col>
                    <v-col cols="8" class="text-right">
                        <v-btn
                            color="error"
                            variant="text"
                            size="small"
                            :disabled="localBoundingBoxes.length === 1"
                            @click="removeSelectedBoundingBox"
                        >
                            Remove current bounding box
                        </v-btn>
                    </v-col>
                </v-row>

                <v-row dense>
                    <v-col cols="12">
                        <v-autocomplete
                            label="Use pre-defined bounding box (optional)"
                            item-title="name"
                            item-value="alpha-3"
                            :items="filteredCountryCodeList"
                            :model-value="selectedCountryCodes[selectedBoundingBoxIndex]"
                            @update:modelValue="applyAutoBbox"
                            hint="Not available for all countries"
                            persistent-hint
                            variant="outlined"
                        ></v-autocomplete>
                    </v-col>
                </v-row>

                <v-row dense>
                    <v-col cols="6">
                        <v-text-field
                            label="North Latitude"
                            type="number"
                            :model-value="selectedBoundingBox.northLatitude"
                            @update:modelValue="(value) => updateSelectedBoxField('northLatitude', value)"
                            :rules="[rules.required, rules.latitude]"
                            variant="outlined"
                            clearable
                        ></v-text-field>
                    </v-col>
                    <v-col cols="6">
                        <v-text-field
                            label="South Latitude"
                            type="number"
                            :model-value="selectedBoundingBox.southLatitude"
                            @update:modelValue="(value) => updateSelectedBoxField('southLatitude', value)"
                            :rules="[rules.required, rules.latitude]"
                            variant="outlined"
                            clearable
                        ></v-text-field>
                    </v-col>
                </v-row>

                <v-row dense>
                    <v-col cols="6">
                        <v-text-field
                            label="West Longitude"
                            type="number"
                            :model-value="selectedBoundingBox.westLongitude"
                            @update:modelValue="(value) => updateSelectedBoxField('westLongitude', value)"
                            :rules="[rules.required, rules.longitude]"
                            variant="outlined"
                            clearable
                        ></v-text-field>
                    </v-col>
                    <v-col cols="6">
                        <v-text-field
                            label="East Longitude"
                            type="number"
                            :model-value="selectedBoundingBox.eastLongitude"
                            @update:modelValue="(value) => updateSelectedBoxField('eastLongitude', value)"
                            :rules="[rules.required, rules.longitude]"
                            variant="outlined"
                            clearable
                        ></v-text-field>
                    </v-col>
                </v-row>

                <v-row dense>
                    <v-col cols="12">
                        <v-btn
                            color="#64BF40"
                            append-icon="mdi-plus"
                            block
                            :disabled="hasIncompleteBoundingBoxes"
                            @click="addBoundingBox"
                        >
                            Add Bounding Box
                        </v-btn>
                    </v-col>
                </v-row>

                <v-row v-if="hasIncompleteBoundingBoxes" dense>
                    <v-col cols="12">
                        <p class="hint-text hint-invalid mb-0">
                            Provide four coordinates for each bounding box.
                        </p>
                    </v-col>
                </v-row>
            </v-card>
        </v-col>

        <v-col cols="12" md="7">
            <bbox-editor
                :box-bounds-list="combinedBoundsForMap"
                :selected-box-index="selectedBoundingBoxIndex"
                :interactive="true"
                @update:selectedBoxBounds="updateSelectedBoxFromMap"
                id="bbox-editor-multipolygon"
            ></bbox-editor>
        </v-col>
    </v-row>
</template>

<script>
import { defineComponent, computed, ref, watch } from "vue";
import BboxEditor from "@/components/BboxEditor.vue";

const createEmptyBoundingBox = () => ({
    northLatitude: null,
    southLatitude: null,
    eastLongitude: null,
    westLongitude: null
});

const toNumberOrNull = (value) => {
    if (value === null || value === undefined || value === "") {
        return null;
    }
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
};

const isCompleteBoundingBox = (bbox) => {
    return Number.isFinite(toNumberOrNull(bbox?.northLatitude))
        && Number.isFinite(toNumberOrNull(bbox?.southLatitude))
        && Number.isFinite(toNumberOrNull(bbox?.eastLongitude))
        && Number.isFinite(toNumberOrNull(bbox?.westLongitude));
};

export default defineComponent({
    name: "SpatialProperties",
    components: {
        BboxEditor
    },
    props: {
        modelValue: {
            type: Array,
            default: () => [createEmptyBoundingBox()]
        },
        filteredCountryCodeList: {
            type: Array,
            default: () => []
        },
        boundingBoxes: {
            type: Object,
            default: () => ({})
        },
        rules: {
            type: Object,
            required: true
        }
    },
    emits: ["update:modelValue"],
    setup(props, { emit }) {
        const selectedCountryCodes = ref({ 0: null });
        const selectedBoundingBoxIndex = ref(0);

        const localBoundingBoxes = computed(() => {
            if (Array.isArray(props.modelValue) && props.modelValue.length > 0) {
                return props.modelValue;
            }
            return [createEmptyBoundingBox()];
        });

        const cloneBoundingBoxes = () => {
            return localBoundingBoxes.value.map((bbox) => ({
                northLatitude: toNumberOrNull(bbox.northLatitude),
                southLatitude: toNumberOrNull(bbox.southLatitude),
                eastLongitude: toNumberOrNull(bbox.eastLongitude),
                westLongitude: toNumberOrNull(bbox.westLongitude)
            }));
        };

        const emitBoundingBoxes = (nextBoxes) => {
            emit("update:modelValue", nextBoxes);
        };

        const boundingBoxOptions = computed(() => {
            return localBoundingBoxes.value.map((_, index) => ({
                title: `bbox-${index + 1}`,
                value: index
            }));
        });

        const selectedBoundingBox = computed(() => {
            return localBoundingBoxes.value[selectedBoundingBoxIndex.value] || createEmptyBoundingBox();
        });

        const hasIncompleteBoundingBoxes = computed(() => {
            return localBoundingBoxes.value.some((bbox) => !isCompleteBoundingBox(bbox));
        });

        const combinedBoundsForMap = computed(() => {
            return localBoundingBoxes.value
                .filter((bbox) => isCompleteBoundingBox(bbox))
                .map((bbox) => [
                    toNumberOrNull(bbox.northLatitude),
                    toNumberOrNull(bbox.eastLongitude),
                    toNumberOrNull(bbox.southLatitude),
                    toNumberOrNull(bbox.westLongitude)
                ]);
        });

        const updateSelectedBoxField = (field, value) => {
            const nextBoxes = cloneBoundingBoxes();
            nextBoxes[selectedBoundingBoxIndex.value][field] = toNumberOrNull(value);
            emitBoundingBoxes(nextBoxes);
        };

        const updateSelectedBoxFromMap = (bounds) => {
            const nextBoxes = cloneBoundingBoxes();
            nextBoxes[selectedBoundingBoxIndex.value] = {
                northLatitude: toNumberOrNull(bounds?.northLatitude),
                southLatitude: toNumberOrNull(bounds?.southLatitude),
                eastLongitude: toNumberOrNull(bounds?.eastLongitude),
                westLongitude: toNumberOrNull(bounds?.westLongitude)
            };
            emitBoundingBoxes(nextBoxes);
        };

        const addBoundingBox = () => {
            const nextBoxes = cloneBoundingBoxes();
            nextBoxes.push(createEmptyBoundingBox());
            emitBoundingBoxes(nextBoxes);
            selectedBoundingBoxIndex.value = nextBoxes.length - 1;
            selectedCountryCodes.value[selectedBoundingBoxIndex.value] = null;
        };

        const removeSelectedBoundingBox = () => {
            const nextBoxes = cloneBoundingBoxes();
            nextBoxes.splice(selectedBoundingBoxIndex.value, 1);
            if (nextBoxes.length === 0) {
                nextBoxes.push(createEmptyBoundingBox());
            }
            emitBoundingBoxes(nextBoxes);

            const nextIndex = Math.min(selectedBoundingBoxIndex.value, nextBoxes.length - 1);
            selectedBoundingBoxIndex.value = Math.max(0, nextIndex);
        };

        const getAlpha2Code = (alpha3Code) => {
            if (alpha3Code === "int") {
                return "int";
            }
            const country = props.filteredCountryCodeList.find((item) => item["alpha-3"] === alpha3Code);
            return country ? country["alpha-2"].toLowerCase() : null;
        };

        const applyAutoBbox = (alpha3Code) => {
            selectedCountryCodes.value[selectedBoundingBoxIndex.value] = alpha3Code;
            const alpha2Code = getAlpha2Code(alpha3Code);
            if (!alpha2Code || !props.boundingBoxes[alpha2Code]) {
                return;
            }

            const bbox = props.boundingBoxes[alpha2Code]["bbox"];
            if (!bbox) {
                return;
            }

            const nextBoxes = cloneBoundingBoxes();
            nextBoxes[selectedBoundingBoxIndex.value] = {
                northLatitude: toNumberOrNull(bbox.maxy),
                eastLongitude: toNumberOrNull(bbox.maxx),
                southLatitude: toNumberOrNull(bbox.miny),
                westLongitude: toNumberOrNull(bbox.minx)
            };
            emitBoundingBoxes(nextBoxes);
        };

        watch(localBoundingBoxes, (boxes) => {
            if (selectedBoundingBoxIndex.value > boxes.length - 1) {
                selectedBoundingBoxIndex.value = Math.max(0, boxes.length - 1);
            }
        });

        return {
            selectedCountryCodes,
            selectedBoundingBoxIndex,
            localBoundingBoxes,
            boundingBoxOptions,
            selectedBoundingBox,
            hasIncompleteBoundingBoxes,
            combinedBoundsForMap,
            updateSelectedBoxField,
            updateSelectedBoxFromMap,
            addBoundingBox,
            removeSelectedBoundingBox,
            applyAutoBbox
        };
    }
});
</script>
