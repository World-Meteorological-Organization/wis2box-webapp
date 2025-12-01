<template>
  <v-card style="min-height: 400px" :id="id" ></v-card>
</template>

<script>
import { defineComponent, ref, computed, onMounted, watch, onBeforeMount } from 'vue';
import { VCard, VCardTitle, VCardText } from 'vuetify/lib/components/index.mjs';
import "leaflet/dist/leaflet.css";
import L from 'leaflet'

// geojson validator
import * as gjv from 'geojson-validation';

export default defineComponent({
  name: "LocatorMap",
  props: {
    center: {
      type: Object,
      default: () => ({lat: 0, lng: 0})
    },
    zoom: {
      type: Number,
      default: 2
    },
    id: {
      type: String,
      default: "map"
    },
    longitude: {
      type: Number,
      default: 0
    },
    latitude: {
      type: Number,
      default: 0
    }
  },
  data(){
    return {
    }
  },
  components: {
    VCard,
    VCardTitle,
    VCardText,
  },
  setup( props, {emit} ) {
    const mapContainer = ref(null);
    const map = ref(null);
    const markerLayer = ref(null);

    mapContainer.value = props.id;


    // 'hack' to fix leaflet marker issue
    var mapMarker = new L.Icon({
      iconUrl: import.meta.env.VITE_BASE_URL + '/assets/marker-icon.png',
      shadowUrl: import.meta.env.VITE_BASE_URL + '/assets/marker-shadow.png',
      iconAnchor: [12, 41], // Adjust the anchor point to bottom center
      shadowAnchor: [12, 41] // Adjust the shadow anchor to match the icon
    });

    const addMarker = (feature, latlng) => {
      return L.marker(latlng, {icon: mapMarker});
    };

    const geom = computed( () => ({
      type: "Feature",
      geometry: {
        type: "Point",
        coordinates: [props.longitude, props.latitude]
      },
      properties: {}
      }));

    onMounted( () =>{
      map.value = L.map(props.id, {zoomAnimation:false, fadeAnimation:true, markerZoomAnimation:true}).setView( props.center, props.zoom );
      map.value.attributionControl.setPrefix('');
      L.tileLayer(`${import.meta.env.VITE_BASEMAP_URL}`, {attribution: `${import.meta.env.VITE_BASEMAP_ATTRIBUTION}`}).addTo(map.value);
      // check whether we have a location to show
      if( geom.value.geometry ){
        updateMarker();
      };
      emit('mapLoaded', map.value);
      // hack to fix leaflet resize issue 
      setTimeout(function() { window.dispatchEvent(new Event('resize')) }, 400);
    });

    const updateMarker = async () => {
      if( markerLayer.value ){
        markerLayer.value.remove();
      }
      // now check whether the new marker is valid and plot
      if( ! (isNaN(geom.value.geometry.coordinates[0]) || isNaN(geom.value.geometry.coordinates[1]))  ){
        if( gjv.isFeature(geom.value) ){
          markerLayer.value = L.geoJSON(geom.value, {pointToLayer: addMarker}).addTo(map.value);
          map.value.fitBounds(markerLayer.value.getBounds());
          map.value.setZoom(10);
        }
      }
    };

    watch( geom, () => {
      updateMarker();
    })

    return {mapContainer};
  }
})
</script>
