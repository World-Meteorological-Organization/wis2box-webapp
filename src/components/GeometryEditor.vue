<template>
    <v-card-title>
        Spatial Properties
        <v-btn icon="mdi-comment-question" variant="text" size="small" @click="showHelp = true" />
    </v-card-title>
    <v-row dense>
        <v-col cols="12" md="5">
            <v-autocomplete
                v-model="selectedCountry"
                label="Add pre-defined country bounding box"
                :items="countries"
                item-title="name"
                item-value="alpha-2"
                variant="outlined"
                clearable
                :disabled="editing"
                @update:modelValue="addCountryBox"
            />
            <v-btn color="error" prepend-icon="mdi-delete" block :disabled="!modelValue || editing" @click="clearGeometry">
                Clear Geometry
            </v-btn>
            <v-btn v-if="canSplitGeometry" color="#003DA5" prepend-icon="mdi-content-cut" block
                class="mt-3" :disabled="editing" @click="splitAtAntimeridian">
                Split at Antimeridian
            </v-btn>
            <v-alert v-if="splitError" type="error" variant="tonal" class="mt-3">
                {{ splitError }}
            </v-alert>
            <v-alert v-if="geometryError" type="error" variant="tonal" class="mt-3">
                {{ geometryError }}
            </v-alert>
        </v-col>
        <v-col cols="12" md="7">
            <div ref="mapElement" class="geometry-map" aria-label="Dataset geometry map"></div>
        </v-col>
    </v-row>
    <v-dialog v-model="showHelp" max-width="600px">
        <v-card>
            <v-toolbar title="Spatial Properties" color="#003DA5">
                <v-btn icon="mdi-close" variant="text" size="small" @click="showHelp = false" />
            </v-toolbar>
            <v-card-text>
                <p>Use the polygon tool to draw an irregular extent. Click each vertex, then click the
                    first vertex to finish. Use the rectangle tool for a bounding box.</p>
                <br>
                <p>Each new shape adds another polygon. Use the edit tool to move or add vertices, or
                    the delete tool to remove shapes. Choose Save to keep the map edits or Cancel to discard them.</p>
                <br>
                <p>Country presets add rectangular extents as a starting point. The automatic bounding box created 
                    may be incorrect for the country, so please verify it before proceeding.</p>
                <br>
                <p>After drawing across 180 degrees longitude, choose Split at Anti-meridian to create separate polygons on
                    either side.</p>
                <br>
                <p>Move the cursor over the map to see its longitude and latitude in decimal degrees.</p>
            </v-card-text>
        </v-card>
    </v-dialog>
</template>

<script>
import { computed, onMounted, onBeforeUnmount, ref, watch } from 'vue';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import 'leaflet-draw';
import 'leaflet-draw/dist/leaflet.draw.css';
import { area, bboxPolygon, booleanValid, featureCollection, intersect, kinks, polygon } from '@turf/turf';

const unwrapPolygonLongitudes = (rings) => {
    if (!Array.isArray(rings) || rings.length !== 1) {
        throw new Error('Only polygons without holes can be split.');
    }
    const ring = rings[0];
    if (!Array.isArray(ring) || ring.length < 4 || ring.some((position) =>
        !Array.isArray(position) || ![2, 3].includes(position.length)
        || !position.every(Number.isFinite) || Math.abs(position[1]) > 90)
        || JSON.stringify(ring[0]) !== JSON.stringify(ring[ring.length - 1])) {
        throw new Error('Provide a closed polygon with valid coordinates before splitting.');
    }
    const hasUnwrappedCoordinates = ring.some(([longitude]) => Math.abs(longitude) > 180);
    const unwrapped = [];
    ring.forEach((position) => {
        let longitude = position[0];
        if (!hasUnwrappedCoordinates && unwrapped.length > 0) {
            const previous = unwrapped[unwrapped.length - 1][0];
            const difference = longitude - ring[unwrapped.length - 1][0];
            if (Math.abs(difference) !== 360) {
                longitude += 360 * Math.round((previous - longitude) / 360);
            } else {
                longitude = previous + difference;
            }
        }
        unwrapped.push([longitude, ...position.slice(1)]);
    });
    if (JSON.stringify(unwrapped[0]) !== JSON.stringify(unwrapped[unwrapped.length - 1])) {
        throw new Error('Polygon must not wind around the world.');
    }
    const longitudes = unwrapped.map(([longitude]) => longitude);
    if (Math.max(...longitudes) - Math.min(...longitudes) > 360) {
        throw new Error('Polygon must not span more than one world.');
    }
    return [unwrapped];
};

export const hasAntimeridianCrossing = (geometry) => {
    if (!geometry || !['Polygon', 'MultiPolygon'].includes(geometry.type)) return false;
    try {
        const polygons = geometry.type === 'Polygon' ? [geometry.coordinates] : geometry.coordinates;
        return polygons.some((rings) => unwrapPolygonLongitudes(rings)[0]
            .some(([longitude]) => longitude < -180 || longitude > 180));
    } catch {
        return false;
    }
};

export const splitGeometryAtAntimeridian = (geometry) => {
    if (!geometry || !['Polygon', 'MultiPolygon'].includes(geometry.type)) {
        throw new Error('Invalid geometry. Use the icons on the top-right of the map to add one or more geometry layers');
    }
    const polygons = geometry.type === 'Polygon' ? [geometry.coordinates] : geometry.coordinates;
    const pieces = [];
    polygons.forEach((rings) => {
        const unwrapped = unwrapPolygonLongitudes(rings);
        const feature = polygon(unwrapped);
        if (!booleanValid(feature) || kinks(feature).features.length > 0 || area(feature) <= 0) {
            throw new Error('Polygon must enclose an area without intersecting itself before splitting.');
        }
        const longitudes = unwrapped[0].map(([longitude]) => longitude);
        const minimum = Math.min(...longitudes);
        const maximum = Math.max(...longitudes);
        if (minimum >= -180 && maximum <= 180) {
            pieces.push(unwrapped);
            return;
        }
        const firstWorld = Math.floor((minimum + 180) / 360);
        const lastWorld = Math.ceil((maximum + 180) / 360) - 1;
        for (let world = firstWorld; world <= lastWorld; world++) {
            const offset = world * 360;
            const clipped = intersect(featureCollection([
                feature, bboxPolygon([-180 + offset, -90, 180 + offset, 90])
            ]));
            if (!clipped) continue;
            const clippedPolygons = clipped.geometry.type === 'Polygon'
                ? [clipped.geometry.coordinates] : clipped.geometry.coordinates;
            clippedPolygons.forEach((coordinates) => {
                pieces.push(coordinates.map((ring) => ring.map(([longitude, latitude]) => [
                    Math.max(-180, Math.min(180, longitude - offset)), latitude
                ])));
            });
        }
    });
    const result = pieces.length === 1
        ? { type: 'Polygon', coordinates: pieces[0] }
        : { type: 'MultiPolygon', coordinates: pieces };
    const error = geometryValidationError(result);
    if (error) throw new Error(error);
    return result;
};

export const geometryValidationError = (geometry) => {
    if (!geometry || !['Polygon', 'MultiPolygon'].includes(geometry.type)) {
        return 'Invalid geometry. Use the icons on the top-right of the map to add one or more geometry layers.';
    }
    const polygons = geometry.type === 'Polygon' ? [geometry.coordinates] : geometry.coordinates;
    if (!Array.isArray(polygons) || polygons.length === 0) {
        return 'Geometry must contain at least one polygon.';
    }
    for (const rings of polygons) {
        if (!Array.isArray(rings) || rings.length !== 1) {
            return 'Each polygon must contain one exterior ring. Holes are not supported by this editor.';
        }
        for (const ring of rings) {
            if (!Array.isArray(ring) || ring.length < 4) {
                return 'Each ring must contain at least three vertices and a closing coordinate.';
            }
            if (ring.some((position) => !Array.isArray(position)
                || ![2, 3].includes(position.length)
                || !position.every(Number.isFinite)
                || position[1] < -90 || position[1] > 90)) {
                return 'Coordinates must be [longitude, latitude] within [-180, 180] and [-90, 90].';
            }
            if (JSON.stringify(ring[0]) !== JSON.stringify(ring[ring.length - 1])) {
                return 'Each polygon ring must be closed (first and last coordinates must match).';
            }
        }
        if (hasAntimeridianCrossing({ type: 'Polygon', coordinates: rings })) {
            return 'Polygon crosses the longitude boundary. Choose Split at Antimeridian before submitting.';
        }
        if (rings[0].some(([longitude]) => longitude < -180 || longitude > 180)) {
            return 'Longitude must be between -180 and 180.';
        }
        try {
            const feature = polygon(rings);
            if (!booleanValid(feature) || kinks(feature).features.length > 0 || area(feature) <= 0) {
                return 'Polygons must enclose an area without intersecting themselves.';
            }
        } catch {
            return 'Invalid polygon coordinates.';
        }
    }
    try {
        if (!booleanValid(geometry)) {
            return 'Invalid geometry. Delete and redraw the geometry using the map tools.';
        }
    } catch {
        return 'Invalid geometry. Delete and redraw the geometry using the map tools.';
    }
    return '';
};

export default {
    name: 'GeometryEditor',
    props: {
        modelValue: { type: Object, default: null }
    },
    emits: ['update:modelValue', 'update:valid'],
    setup(props, { emit }) {
        const mapElement = ref(null);
        const showHelp = ref(false);
        const editing = ref(false);
        const selectedCountry = ref(null);
        const countries = ref([]);
        const splitError = ref('');
        const canSplitGeometry = computed(() => hasAntimeridianCrossing(props.modelValue));
        const geometryError = computed(() => geometryValidationError(props.modelValue));
        let countryBoxes = {};
        let map;
        let drawnItems;
        let resizeObserver;
        let lastMapGeometry;

        const reportValidity = () => {
            emit('update:valid', !editing.value && !geometryError.value);
        };

        const renderGeometry = () => {
            if (!map || !drawnItems) return;
            const serialized = JSON.stringify(props.modelValue);
            if (serialized === lastMapGeometry) return;
            drawnItems.clearLayers();
            lastMapGeometry = serialized;
            if (!props.modelValue || geometryError.value) return;
            const polygons = props.modelValue.type === 'Polygon'
                ? [props.modelValue.coordinates] : props.modelValue.coordinates;
            polygons.forEach((coordinates) => {
                L.geoJSON({ type: 'Polygon', coordinates }, {
                    style: { color: '#003DA5', weight: 2, fillOpacity: 0.15 }
                }).eachLayer((layer) => drawnItems.addLayer(layer));
            });
            if (drawnItems.getLayers().length) {
                map.fitBounds(drawnItems.getBounds(), { padding: [20, 20], maxZoom: 8 });
            }
        };

        const publishLayers = () => {
            const polygons = drawnItems.getLayers().map((layer) => layer.toGeoJSON(false).geometry.coordinates);
            const geometry = polygons.length === 0 ? null : polygons.length === 1
                ? { type: 'Polygon', coordinates: polygons[0] }
                : { type: 'MultiPolygon', coordinates: polygons };
            lastMapGeometry = JSON.stringify(geometry);
            emit('update:modelValue', geometry);
        };

        const clearGeometry = () => {
            emit('update:modelValue', null);
            emit('update:valid', false);
        };

        const splitAtAntimeridian = () => {
            try {
                const geometry = splitGeometryAtAntimeridian(props.modelValue);
                emit('update:modelValue', geometry);
            } catch (error) {
                splitError.value = error.message;
            }
        };

        const addCountryBox = (code) => {
            const box = countryBoxes[code]?.bbox;
            if (!box || !drawnItems) return;
            const coordinates = [[
                [box.minx, box.miny], [box.maxx, box.miny],
                [box.maxx, box.maxy], [box.minx, box.maxy], [box.minx, box.miny]
            ]];
            L.geoJSON({ type: 'Polygon', coordinates }).eachLayer((layer) => drawnItems.addLayer(layer));
            publishLayers();
            map.fitBounds(drawnItems.getBounds(), { padding: [20, 20], maxZoom: 8 });
            selectedCountry.value = null;
        };

        watch(() => props.modelValue, () => {
            splitError.value = '';
            renderGeometry();
            reportValidity();
        }, { immediate: true, deep: true });

        onMounted(async () => {
            map = L.map(mapElement.value).setView([0, 0], 2);
            map.attributionControl.setPrefix('');
            L.tileLayer(import.meta.env.VITE_BASEMAP_URL, {
                attribution: import.meta.env.VITE_BASEMAP_ATTRIBUTION
            }).addTo(map);
            drawnItems = L.featureGroup().addTo(map);
            map.addControl(new L.Control.Draw({
                position: 'topright',
                draw: {
                    polygon: { allowIntersection: false, showArea: false },
                    rectangle: { showArea: false },
                    polyline: false, circle: false, marker: false, circlemarker: false
                },
                edit: { featureGroup: drawnItems, remove: true }
            }));
            const coordinateTooltip = L.tooltip({
                direction: 'top',
                offset: [0, -8],
                opacity: 0.95,
                interactive: false
            });
            map.on('mousemove', (event) => {
                const longitude = event.latlng.lng.toFixed(8);
                const latitude = event.latlng.lat.toFixed(8);
                coordinateTooltip
                    .setLatLng(event.latlng)
                    .setContent(`Lon: ${longitude}°<br>Lat: ${latitude}°`);
                if (!map.hasLayer(coordinateTooltip)) {
                    coordinateTooltip.addTo(map);
                }
            });
            map.on('mouseout', () => coordinateTooltip.remove());
            map.on(L.Draw.Event.CREATED, (event) => {
                drawnItems.addLayer(event.layer);
                publishLayers();
            });
            map.on(L.Draw.Event.EDITED, publishLayers);
            map.on(L.Draw.Event.DELETED, publishLayers);
            map.on('draw:editstart draw:deletestart draw:drawstart', () => {
                editing.value = true;
                reportValidity();
            });
            map.on('draw:editstop draw:deletestop draw:drawstop', () => {
                editing.value = false;
                reportValidity();
            });
            renderGeometry();
            resizeObserver = new ResizeObserver(() => map.invalidateSize());
            resizeObserver.observe(mapElement.value);
            try {
                const base = import.meta.env.VITE_BASE_URL;
                const responses = await Promise.all([
                    fetch(`${base}/codelists/iso-3366-1-countries.json`),
                    fetch(`${base}/codelists/country-bbox.json`)
                ]);
                if (responses.some((response) => !response.ok)) throw new Error('Failed to load country bounding boxes.');
                const [countryList, boxes] = await Promise.all(responses.map((response) => response.json()));
                countryBoxes = boxes.countries;
                countries.value = [
                    { name: 'Global', 'alpha-2': 'int' },
                    ...countryList.filter((country) => country['alpha-2'].toLowerCase() in countryBoxes)
                        .map((country) => ({ ...country, 'alpha-2': country['alpha-2'].toLowerCase() }))
                ];
            } catch (error) {
                console.error(error);
            }
        });

        onBeforeUnmount(() => {
            resizeObserver?.disconnect();
            map?.remove();
        });

        return {
            mapElement, showHelp, geometryError, editing,
            selectedCountry, countries, clearGeometry, addCountryBox,
            canSplitGeometry, splitError, splitAtAntimeridian
        };
    }
};
</script>

<style scoped>
.geometry-map {
    height: 480px;
    width: 100%;
    z-index: 0;
}
</style>