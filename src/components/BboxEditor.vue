<template>
    <v-card variant="outlined" color="#757575">
        <v-card-item style="width: 100%; height: 100%; min-height: 405px" :id="id"></v-card-item>
    </v-card>
</template>

<script>
import { defineComponent, ref, computed, onMounted, watch } from 'vue';
import { VCard } from 'vuetify/lib/components/index.mjs';
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import "leaflet-draw";
import "leaflet-draw/dist/leaflet.draw.css";

export default defineComponent({
    name: "BboxEditor",
    components: {
        VCard
    },
    emits: ["update:selectedBoxBounds"],
    props: {
        boxBounds: {
            type: Array,
            default: null
        },
        boxBoundsList: {
            type: Array,
            default: () => []
        },
        selectedBoxIndex: {
            type: Number,
            default: 0
        },
        interactive: {
            type: Boolean,
            default: false
        }
    },
    setup(props, { attrs, emit }) {

        // Reactive variables
        const map = ref(null);
        const fallbackId = `bbox-map-${Math.random().toString(36).slice(2, 8)}`;
        const id = ref(attrs.id || fallbackId);
        const rectangles = ref([]);
        const drawnItems = ref(null);
        const drawControl = ref(null);
        const zoom = ref(1.5);
        const centre = ref([0, 0]);

        const isFiniteBoxBounds = (bounds) => {
            if (!Array.isArray(bounds) || bounds.length !== 4) {
                return false;
            }
            return bounds.every((value) => Number.isFinite(Number(value)));
        };

        // Computed property for one or many bounds
        const boundsList = computed(() => {
            if (Array.isArray(props.boxBoundsList) && props.boxBoundsList.length > 0) {
                return props.boxBoundsList
                    .map((bounds, sourceIndex) => ({ bounds, sourceIndex }))
                    .filter((item) => isFiniteBoxBounds(item.bounds));
            }
            if (isFiniteBoxBounds(props.boxBounds)) {
                return [{ bounds: props.boxBounds, sourceIndex: 0 }];
            }
            return [];
        });

        const clearRectangles = () => {
            rectangles.value.forEach((rectangle) => rectangle.remove());
            rectangles.value = [];
        };

        const toBoundsArray = (layerBounds) => {
            const northEast = layerBounds.getNorthEast();
            const southWest = layerBounds.getSouthWest();
            return [northEast.lat, northEast.lng, southWest.lat, southWest.lng];
        };

        const normalizeLongitude = (longitude) => {
            if (!Number.isFinite(Number(longitude))) {
                return longitude;
            }
            return ((Number(longitude) + 180) % 360 + 360) % 360 - 180;
        };

        const emitSelectedBounds = (layer) => {
            if (!layer) {
                emit("update:selectedBoxBounds", {
                    northLatitude: null,
                    eastLongitude: null,
                    southLatitude: null,
                    westLongitude: null
                });
                return;
            }

            const [northLatitude, eastLongitudeRaw, southLatitude, westLongitudeRaw] = toBoundsArray(layer.getBounds());
            const eastLongitude = normalizeLongitude(eastLongitudeRaw);
            const westLongitude = normalizeLongitude(westLongitudeRaw);
            emit("update:selectedBoxBounds", {
                northLatitude,
                eastLongitude,
                southLatitude,
                westLongitude
            });
        };

        const clearDrawnItems = () => {
            if (!drawnItems.value) {
                return;
            }
            drawnItems.value.clearLayers();
        };

        const addOrUpdateDrawControl = (currentMap) => {
            if (!currentMap || !props.interactive || !drawnItems.value) {
                return;
            }

            if (drawControl.value) {
                currentMap.removeControl(drawControl.value);
            }

            drawControl.value = new L.Control.Draw({
                position: "topright",
                draw: {
                    polyline: false,
                    polygon: false,
                    circle: false,
                    marker: false,
                    circlemarker: false,
                    rectangle: false
                },
                edit: {
                    featureGroup: drawnItems.value,
                    edit: {},
                    remove: true
                }
            });

            currentMap.addControl(drawControl.value);
        };

        onMounted(() => {
            // Add 1 second delay to load map or Vue will call mounted before DOM is available
            setTimeout(() => {
                map.value = L.map(id.value).setView(centre.value, zoom.value);
                map.value.attributionControl.setPrefix('');
                L.tileLayer(`${import.meta.env.VITE_BASEMAP_URL}`, { attribution: `${import.meta.env.VITE_BASEMAP_ATTRIBUTION}` }).addTo(map.value);

                drawnItems.value = L.featureGroup().addTo(map.value);
                addOrUpdateDrawControl(map.value);

                map.value.on(L.Draw.Event.CREATED, (event) => {
                    if (!props.interactive) {
                        return;
                    }

                    clearDrawnItems();
                    const layer = event.layer;
                    drawnItems.value.addLayer(layer);
                    emitSelectedBounds(layer);
                });

                map.value.on(L.Draw.Event.EDITED, (event) => {
                    if (!props.interactive) {
                        return;
                    }

                    event.layers.eachLayer((layer) => {
                        emitSelectedBounds(layer);
                    });
                });

                map.value.on(L.Draw.Event.DELETED, () => {
                    if (!props.interactive) {
                        return;
                    }
                    emitSelectedBounds(null);
                });
            }, 1)
        });

        watch([boundsList, map, () => props.selectedBoxIndex, () => props.interactive], ([newBoundsList, currentMap]) => {
            if (!currentMap) {
                return;
            }

            clearRectangles();
            clearDrawnItems();

            if (props.interactive) {
                addOrUpdateDrawControl(currentMap);
            } else if (drawControl.value) {
                currentMap.removeControl(drawControl.value);
                drawControl.value = null;
            }

            if (newBoundsList.length > 0) {
                newBoundsList.forEach((boxData) => {
                    const boxBounds = boxData.bounds;
                    const isSelected = boxData.sourceIndex === props.selectedBoxIndex;
                    const bounds = L.latLngBounds(
                        L.latLng(boxBounds[0], boxBounds[1]),
                        L.latLng(boxBounds[2], boxBounds[3])
                    );

                    if (props.interactive && isSelected && drawnItems.value) {
                        const editableRectangle = L.rectangle(bounds, {
                            color: "#003DA5",
                            weight: 2,
                            fillOpacity: 0.15
                        });
                        drawnItems.value.addLayer(editableRectangle);
                    } else {
                        const rectangle = L.rectangle(bounds, {
                            color: isSelected ? "#003DA5" : "#1FB5DB",
                            weight: 2,
                            fillOpacity: 0.15
                        }).addTo(currentMap);
                        rectangles.value.push(rectangle);
                    }
                });

                const allLayers = [...rectangles.value];
                if (drawnItems.value) {
                    drawnItems.value.eachLayer((layer) => {
                        allLayers.push(layer);
                    });
                }

                if (allLayers.length > 0) {
                    const featureGroup = L.featureGroup(allLayers);
                    currentMap.fitBounds(featureGroup.getBounds(), { padding: [10, 10] });
                }
            }
        }, { immediate: true });

        return {
            map,
            id
        }
    }
});
</script>