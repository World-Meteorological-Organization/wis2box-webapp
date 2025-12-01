<template>
    <v-card>
        <v-card-title>Map View</v-card-title>
        <v-card-item style="width: 100%; height: 100%; min-height: 600px" :id="id"></v-card-item>
    </v-card>
</template>

<script>
import { defineComponent, ref, computed, onMounted, watch } from 'vue';
import { VCard } from 'vuetify/lib/components/index.mjs';

// Leaflet imports
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import '@fortawesome/fontawesome-free/css/all.css';


export default defineComponent({
    name: "StationMap",
    props: {
        messages: {
            type: Array,
            required: true,
            default: () => []
        },
        center: {
            type: Object,
            required: false,
            default: () => ({ lat: 0, lng: 0 })
        },
        zoom: {
            type: Number,
            required: false,
            default: 8
        },
        id: {
            type: String,
            required: false,
            default: "map"
        }
    },
    components: {
        VCard
    },
    setup(props) {

        // Reactive variables
        const map = ref(null);
        const stationLayer = ref(null);

        // Computed

        // Ensure all necessary data is available before updating the map
        const readyToUpdate = computed(() => {
            return map.value && stationLayer.value && props.messages.length > 0;
        });

        // Create geoJSON data from the messages prop
        const features = computed(() => {
            if (props.messages.length === 0) {
                return [];
            }
            return props.messages.map(msg => {
                return {
                    type: 'Feature',
                    id: msg.id,
                    properties: {
                        wigos_station_identifier: msg.wsi
                    },
                    geometry: {
                        type: 'Point',
                        coordinates: msg.coordinates
                    }
                }
            })
        });

        // Count the number of messages published by each WSI at each location
        const wsiCoordCount = computed(() => {
            const counts = {};
            props.messages.forEach(msg => {
                // The key is not just determined by WSI, but also by the coordinates
                // Note: This helps in the example of moving stations e.g. buoys
                let key = `${msg.wsi}_${msg.coordinates[1]}_${msg.coordinates[0]}`
                if (counts[key]) {
                    counts[key]++;
                } else {
                    counts[key] = 1;
                }
            });
            return counts;
        });

        // Fill map with markers when data changes
        const updateMarkers = () => {
            if (!readyToUpdate.value) return;

            // Clear existing markers first
            stationLayer.value.clearLayers();
            // Initialise LatLngBounds object
            let bounds = L.latLngBounds()
            // Structure features array in form [lat, lon] required for markers
            features.value.forEach((feature) => {
                let coords = feature.geometry?.coordinates;

                // Check if coordinates are defined before proceeding
                if (!coords || coords.length < 2) return;

                // Swap coordinates to [lat, lon] for Leaflet
                coords = [feature.geometry.coordinates[1], feature.geometry.coordinates[0]];
                // Define marker styling
                const iconHtml = "<i class='fas fa-location-dot' style='color: #003DA5; font-size: 24px; filter: drop-shadow(2px 2px 0.5px rgba(0,0,0,0.4));'/>"
                let marker = L.marker(coords, {
                    icon: L.divIcon({
                        html: iconHtml,
                        className: 'customIcon',
                        iconSize: L.point(20, 28),  // Set size sufficiently large to handle icon
                        iconAnchor: [10, 28] // Adjust anchor so the tip of the icon is at the coordinates
                    })
                });
                // Define marker key (WSI, lat, lon)
                let key = `${feature.properties.wigos_station_identifier}_${coords[0]}_${coords[1]}`
                // Bind a tooltip to each marker to display the WSI
                marker.bindTooltip(
                    `WSI: ${feature.properties.wigos_station_identifier}<br>
                    Messages: ${wsiCoordCount.value[key]}`, {
                    permanent: false,
                    direction: 'top',
                    // Offset tooltip to avoid covering marker
                    offset: [-5, -15]
                });
                // Set ID for marker, which is a link to
                // the notification
                marker.id = feature.id;
                // Set type of marker
                marker.type = "host";
                // Extend LatLngBounds with coordinates
                stationLayer.value.addLayer(marker);
                bounds.extend(coords)
            })
            if (bounds.isValid()) {
                map.value.fitBounds(bounds);
            }
        };

        onMounted(() => {
            // Create the map, base layer and add it to the DOM
            map.value = L.map(props.id, { zoomAnimation: false, fadeAnimation: true, markerZoomAnimation: true }).setView(props.center, props.zoom);
            map.value.attributionControl.setPrefix('');
            L.tileLayer(`${import.meta.env.VITE_BASEMAP_URL}`, { attribution: `${import.meta.env.VITE_BASEMAP_ATTRIBUTION}` }).addTo(map.value);
            // Initialise the station layer and update with markers
            stationLayer.value = L.layerGroup().addTo(map.value);
            updateMarkers();
        })

        watch(features, () => { updateMarkers() });
    }
})
</script>

<style scoped>
.customIcon {
    /* Ensures the text icon is centered both vertically and horizontally */
    display: flex;
    justify-content: center;
    align-items: center;
    text-align: center;
}
</style>
