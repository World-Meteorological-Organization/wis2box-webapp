<template>
    <!-- Dashboard -->
    <v-row>
        <v-col cols="12">
            <v-row>
                <!-- ApexCharts bar graph for latest notifications received -->
                <v-col cols="7">
                    <v-fade-transition appear>
                        <BarChart :messages="messages" :startDate="startDate" :endDate="endDate"></BarChart>
                    </v-fade-transition>
                </v-col>

                <v-col cols="5">
                    <!-- Top right -->
                    <v-row>
                        <!-- Total number of publications submitted in the last hour -->
                        <v-col cols="12">
                            <v-fade-transition appear>
                                <SummaryStats :messages="messages"></SummaryStats>
                            </v-fade-transition>
                        </v-col>
                    </v-row>

                    <!-- Bottom right -->
                    <!-- List of WSIs and the number of associated notifications -->
                    <v-row>
                        <v-col cols="12">
                            <v-fade-transition appear>
                                <StationStats :messages="messages"></StationStats>
                            </v-fade-transition>
                        </v-col>
                    </v-row>

                </v-col>
            </v-row>

            <!-- Below the rest -->
            <!-- Searchable list of published data with timestamps,
            download and inspect buttons -->
            <v-row>
                <v-col cols="12">
                    <v-fade-transition appear>
                        <PublishedData :messages="messages"></PublishedData>
                    </v-fade-transition>
                </v-col>
            </v-row>

            <!-- Map view of the publications per station -->
            <v-row>
                <v-col cols="12">
                    <v-fade-transition appear>
                        <StationMap :messages="messages" id="station-map"></StationMap>
                    </v-fade-transition>
                </v-col>
            </v-row>
        </v-col>
    </v-row>
</template>

<script>
import { defineComponent, ref, onMounted } from 'vue';
import BarChart from '@/components/monitoring/BarChart.vue';
import SummaryStats from '@/components/monitoring/SummaryStats.vue';
import StationStats from '@/components/monitoring/StationStats.vue';
import PublishedData from '@/components/monitoring/PublishedData.vue';
import StationMap from '@/components/monitoring/StationMap.vue';

export default defineComponent({
    name: 'NotificationDashboard',
    props: {
        datasetID: {
            type: String,
            required: true
        },
        startDate: {
            type: Date,
            required: true
        },
        endDate: {
            type: Date,
            required: true
        },
        wsi: {
            type: String,
            required: false
        },
        limit: {
            type: Number,
            required: true
        },
    },
    components: {
        BarChart,
        SummaryStats,
        StationStats,
        PublishedData,
        StationMap
    },
    setup(props) {
        // Static variables
        const testMode = import.meta.env.VITE_TEST_MODE === "true" || import.meta.env.VITE_API_URL == undefined;
        // Example message of Romania synoptic dataset
        const testMessageSynoptic = [
            {
                "id": "urn:wmo:md:test1-centre:core.test1.test1.test1", 
                "geometry": {
                    "type": "Point",
                    "coordinates": [6.146197, 46.223432, 1]
                },
                "properties": {
                    "data_id": "wis2/rou/rnimh/data/core/weather/surface-based-observations/synop/WIGOS_0-20000-0-15020_20220331T000000",
                    "datetime": "2022-03-31T00:00:00Z",
                    "pubtime": "2023-09-22T08:55:20Z",
                    "wigos_station_identifier": "0-20000-0-15020",
                    "identifier": "urn:wmo:md:test1-centre:core.test1.test1.test1"
                },
                "links": [
                    {
                        "rel": "canonical",
                        "type": "application/bufr",
                        "href": "http://3.73.37.35/data/2022-03-31/wis/rou/rnimh/data/core/weather/surface-based-observations/synop/WIGOS_0-20000-0-15020_20220331T000000.bufr4",
                    },
                    {
                        "rel": "via",
                        "type": "text/html",
                        "href": "https://oscar.wmo.int/surface/#/search/station/stationReportDetails/0-20000-0-15015"
                    }]
            },
            {
                "id": "urn:wmo:md:test1-centre:core.test1.test1.test1",
                "geometry": {
                    "type": "Point",
                    "coordinates": [6.146197, 46.223432, 1]
                },
                "properties": {
                    "data_id": "wis2/rou/rnimh/data/core/weather/surface-based-observations/synop/WIGOS_0-20000-0-15020_20220331T000000",
                    "datetime": "2022-03-31T00:00:00Z",
                    "pubtime": "2023-09-22T08:55:20Z",
                    "wigos_station_identifier": "0-20000-0-15020",
                    "identifier": "urn:wmo:md:test1-centre:core.test1.test1.test1"
                },
                "links": [
                    {
                        "rel": "canonical",
                        "type": "application/bufr",
                        "href": "http://3.73.37.35/data/2022-03-31/wis/rou/rnimh/data/core/weather/surface-based-observations/synop/WIGOS_0-20000-0-15020_20220331T000000.bufr4",
                    },
                    {
                        "rel": "via",
                        "type": "text/html",
                        "href": "https://oscar.wmo.int/surface/#/search/station/stationReportDetails/0-20000-0-15015"
                    }]
            },
            {
                "id": "urn:wmo:md:test1-centre:core.test1.test1.test1",
                "geometry": {
                    "type": "Point",
                    "coordinates": [6.146197, 46.423432, 1]
                },
                "properties": {
                    "data_id": "wis2/rou/rnimh/data/core/weather/surface-based-observations/synop/WIGOS_0-20000-0-15020_20220331T000000",
                    "datetime": "2022-03-31T00:00:00Z",
                    "pubtime": "2023-09-22T08:55:20Z",
                    "wigos_station_identifier": "0-20000-0-15030",
                    "identifier": "urn:wmo:md:test1-centre:core.test1.test1.test1"
                },
                "links": [
                    {
                        "rel": "canonical",
                        "type": "application/bufr",
                        "href": "http://3.73.37.35/data/2022-03-31/wis/rou/rnimh/data/core/weather/surface-based-observations/synop/WIGOS_0-20000-0-15020_20220331T000000.bufr4",
                    },
                    {
                        "rel": "via",
                        "type": "text/html",
                        "href": "https://oscar.wmo.int/surface/#/search/station/stationReportDetails/0-20000-0-15015"
                    }]
            }
        ]
        // Example message of Malawi surface dataset
        const testMessageSurface = [
            {
                "id": "urn:wmo:md:test2-centre:core.test2.test2.test2",
                "geometry": {
                    "type": "Point",
                    "coordinates": [6.146197, 46.223432]
                },
                "properties": {
                    "data_id": "wis2/rou/rnimh/data/core/weather/surface-based-observations/synop/WIGOS_0-20000-0-15015_20220331T000000",
                    "datetime": "2022-03-31T00:00:00Z",
                    "pubtime": "2023-09-19T13:40:49Z",
                    "wigos_station_identifier": "0-20000-0-15015",
                    "identifier": "urn:wmo:md:test2-centre:core.test2.test2.test2"
                },
                "links": [
                    {
                        "rel": "canonical",
                        "type": "application/bufr",
                        "href": "http://3.73.37.35/data/2022-03-31/wis/rou/rnimh/data/core/weather/surface-based-observations/synop/WIGOS_0-20000-0-15015_20220331T000000.bufr4",
                    },
                    {
                        "rel": "via",
                        "type": "text/html",
                        "href": "https://oscar.wmo.int/surface/#/search/station/stationReportDetails/0-20000-0-15015"
                    }]
            }
        ]

        // Reactive variables

        // Messages from API call
        const messages = ref([])

        // Methods

        // Method to get canonical URL from a message
        const getCanonicalInfo = (links) => {
            const canonicalLink = links.find(link => link.rel === "canonical");
            if (canonicalLink) {
                return {
                    'url': canonicalLink.href,
                    'type': canonicalLink.type,
                    'size': canonicalLink.length
                };
            }
            return '';
        }

        // Method to get the messages from the features array
        const getMessagesFromFeatures = (features) => {
            const selectedFields = features.map(item => ({
                id: item.id,
                pubtime: new Date(item.properties.pubtime),
                canonical_url: getCanonicalInfo(item.links).url,
                type: getCanonicalInfo(item.links).type,
                size: getCanonicalInfo(item.links).size,
                wsi: item.properties.wigos_station_identifier,
                coordinates: item.geometry?.coordinates ?? null // Geometry may not be present
            }));
            // sort by pubtime descending
            return selectedFields.sort((a, b) => b.pubtime - a.pubtime);
        }

        // Make API call
        const apiCall = async () => {
            const apiUrl = `${import.meta.env.VITE_API_URL}/collections/messages/items`;
            if (testMode) {
                console.log("TEST_MODE is enabled");
                console.log("Fetching notifications from:", apiUrl);
            }
            try {
                let params;

                // If WSI prop is given, include it in the search:
                if (props.wsi) {
                    params = new URLSearchParams({
                        f: 'json', // Specify the response format as JSON
                        metadata_id: `${props.datasetID}%`, // Filter by dataset
                        sortby: '-datetime', // Sort by time in descending order
                        datetime: `${props.startDate.toISOString()}/${props.endDate.toISOString()}`, // Filter to date range specified by user
                        wigos_station_identifier: `${props.wsi}`, // Filter by WSI searched
                        limit: `${props.limit}`, // Limit number of notifications shown on dashboard
                    });
                }
                else {
                    params = new URLSearchParams({
                        f: 'json', // Specify the response format as JSON
                        metadata_id: `${props.datasetID}%`, // Filter by dataset
                        sortby: '-datetime', // Sort by time in descending order
                        datetime: `${props.startDate.toISOString()}/${props.endDate.toISOString()}`, // Filter to date range specified by user
                        limit: `${props.limit}`, // Limit number of notifications shown on dashboard
                    });
                }
                // Make the HTTP GET request
                if (testMode) {
                    console.log("API request:", `${apiUrl}?${params}`)
                }
                const response = await fetch(`${apiUrl}?${params}`);
                if (!response.ok) {
                    throw new Error(`HTTP error! Status: ${response.status}`);
                }
                else {
                    const data = await response.json();
                    if (data.features) {
                        messages.value = getMessagesFromFeatures(data.features);
                    }
                    else {
                        console.error("API response does not contain features:", data);
                    }
                }
            }
            catch (error) {
                console.error("Error fetching notifications:", error)
            }
        }

        // Retrieve messages
        const updateMessages = async () => {
            // Check if TEST_MODE is set in .env file or if VITE_API_URL is not set
            if (testMode) {
                console.log("TEST_MODE is enabled");
                console.log("Dataset selected: ", props.datasetID);
                // Use example data selected by user
                if (props.datasetID == "urn:wmo:md:test1-centre:core.test1.test1.test1") {
                    messages.value = getMessagesFromFeatures(testMessageSynoptic);
                    console.log(messages.value)
                }
                else if (props.datasetID == "urn:wmo:md:test2-centre:core.test2.test2.test2") {
                    messages.value = getMessagesFromFeatures(testMessageSurface);
                }
            }
            // If not in test mode, make the API call
            else {
                await apiCall();
            }
        }

        // Mounted lifecycle hook to display newest notification dashboard
        onMounted(() => {
            updateMessages();
        })

        return {
            messages,
            updateMessages
        }
    }
});
</script>
