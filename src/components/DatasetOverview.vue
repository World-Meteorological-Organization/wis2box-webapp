<template>
    <v-card-item>
        <div class="overview-header-row">
            <h3 class="mb-0">Dataset Overview</h3>
            <v-select
                v-if="centreIds.length"
                v-model="selectedCentreId"
                :items="centreIdOptions"
                label="Centre ID"
                density="compact"
                variant="outlined"
                item-title="title"
                item-value="value"
                class="centre-selector-inline"
            ></v-select>
        </div>
        <v-progress-circular v-if="isLoadingDatasets" indeterminate size="24" width="3"></v-progress-circular>
        <v-alert v-else-if="datasetErrorMessage" type="error" density="compact" class="mt-2">
            {{ datasetErrorMessage }}
        </v-alert>
        <v-alert v-if="isLoadingDatasetKpis" type="info" density="compact" class="mt-2 mb-2">
                loading local datasets...
        </v-alert>
        <template v-else>
            <div v-if="selectedCentreDatasets.length" class="centre-group mt-3">
                <h4 class="mb-2">Datasets for Centre-ID={{ selectedCentreId }} configured on this instance:</h4>
                <v-list density="compact" class="dataset-list">
                    <v-list-item v-for="dataset in selectedCentreDatasets" :key="dataset.id">
                        <v-card class="dataset-item pa-3">
                            <div class="dataset-item-header">
                                <v-list-item-title class="mr-3">{{ dataset.id }}</v-list-item-title>
                                <div class="dataset-gdc-badges">
                                    <span
                                        v-for="badge in getDatasetGdcBadges(dataset.id)"
                                        :key="`${dataset.id}-${badge.label}`"
                                        class="gdc-badge"
                                        :class="getGdcBadgeClass(badge.found)"
                                        :title="getGdcBadgeHoverText(badge.label, badge.found)"
                                    >
                                        {{ badge.label }}
                                    </span>
                                </div>
                            </div>
                            <v-list-item-subtitle v-if="dataset.title">Title: {{ dataset.title }}</v-list-item-subtitle>
                            <v-list-item-subtitle v-if="dataset.description">Description: {{ dataset.description }}</v-list-item-subtitle>
                            <div class="kpi-grade-row mt-2">
                                <span class="kpi-grade-label">Metadata KPI Grade:</span>
                                <span class="kpi-grade-badge" :class="getDatasetKpiGradeClass(dataset.id)">
                                    {{ getDatasetKpiGrade(dataset.id) }}
                                </span>
                            </div>
                            <div class="mt-3 d-flex flex-wrap ga-2">
                                <v-btn
                                    size="small"
                                    color="#003DA5"
                                    variant="outlined"
                                    :loading="isLoadingKpi && selectedDatasetForKpi?.id === dataset.id"
                                    @click="showMetadataKpi(dataset)"
                                >
                                    Metadata quality assessment
                                </v-btn>
                                <v-btn size="small" color="#003DA5" variant="flat" @click="goToDatasetEditor(dataset)">
                                    Update dataset
                                </v-btn>
                            </div>
                        </v-card>
                    </v-list-item>
                </v-list>
            </div>
            <div class="centre-group mt-3">
                <v-alert v-if="isLoadingOtherDatasets" type="info" density="compact" class="mt-2 mb-2">
                    loading datasets from GDCs...
                </v-alert>
                <template v-else>
                    <div v-if="selectedOtherDatasets.length">
                        <h4 class="mb-2">Other datasets for Centre-ID={{ selectedCentreId }} found in GDCs</h4>
                        <v-list density="compact" class="other-dataset-list">
                            <v-list-item v-for="dataset in selectedOtherDatasets" :key="`other-${dataset.id}`">
                                <v-card class="dataset-item other-dataset-item pa-3">
                                    <div class="dataset-item-header">
                                        <v-list-item-title class="mr-3">{{ dataset.id }}</v-list-item-title>
                                        <div class="dataset-gdc-badges">
                                            <span
                                                v-for="badge in getDatasetGdcBadges(dataset.id)"
                                                :key="`${dataset.id}-${badge.label}`"
                                                class="gdc-badge"
                                                :class="getGdcBadgeClass(badge.found)"
                                                :title="getGdcBadgeHoverText(badge.label, badge.found)"
                                            >
                                                {{ badge.label }}
                                            </span>
                                        </div>
                                    </div>
                                    <v-list-item-subtitle v-if="dataset.title">Title: {{ dataset.title }}</v-list-item-subtitle>
                                    <v-list-item-subtitle v-if="dataset.description">Description: {{ dataset.description }}</v-list-item-subtitle>
                                </v-card>
                            </v-list-item>
                        </v-list>
                    </div>
                    <v-alert v-else type="info" density="compact" class="mt-2">
                        No other datasets with Centre-ID={{ selectedCentreId }} found in GDCs
                    </v-alert>
                </template>
            </div>
            <v-alert v-if="!selectedCentreDatasets.length" type="info" density="compact" class="mt-2">
                No configured datasets found.
            </v-alert>
        </template>

        <v-dialog v-model="showKpiDialog">
            <v-card>
                <v-card-title>Metadata quality assessment</v-card-title>
                <v-card-text>
                    <div>
                        <strong>{{ selectedDatasetForKpi?.id }}</strong><br/>
                        Title: {{ selectedDatasetForKpi?.title || 'N/A' }}<br/>
                        Description: {{ selectedDatasetForKpi?.description || 'N/A' }}
                    </div>
                    <v-progress-circular
                        v-if="isLoadingKpi"
                        indeterminate
                        size="24"
                        width="3"
                        class="mt-4"
                    ></v-progress-circular>
                    <v-alert v-else-if="kpiErrorMessage" type="error" density="compact" class="mt-3">
                        {{ kpiErrorMessage }}
                    </v-alert>
                    <div v-else-if="kpiResult" class="mt-3">
                        <v-card variant="tonal" class="mb-3">
                            <v-card-text>
                                <div><strong>KPI Grade:</strong> {{ kpiResult.summary?.grade ?? 'N/A' }}</div>
                                <div>
                                    <strong>Score:</strong>
                                    {{ kpiResult.summary?.score ?? 'N/A' }} / {{ kpiResult.summary?.total ?? 'N/A' }}
                                </div>
                                <div><strong>Percentage:</strong> {{ formatPercentage(kpiResult.summary?.percentage) }}</div>
                                <div><strong>Generated by:</strong> {{ kpiResult.generated_by ?? 'N/A' }}</div>
                            </v-card-text>
                        </v-card>

                        <div class="text-subtitle-1 mb-2"><strong>Tests</strong></div>
                        <v-table density="compact">
                            <thead>
                                <tr>
                                    <th>Title</th>
                                    <th>Score</th>
                                    <th>Percentage</th>
                                    <th>Comments</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="test in kpiResult.tests || []" :key="test.id">
                                    <td>{{ test.title || test.id }}</td>
                                    <td>{{ test.score ?? 'N/A' }} / {{ test.total ?? 'N/A' }}</td>
                                    <td>{{ formatPercentage(test.percentage) }}</td>
                                    <td class="kpi-comments-cell">{{ formatComments(test.comments) }}</td>
                                </tr>
                            </tbody>
                        </v-table>
                    </div>
                    <v-alert v-else type="info" density="compact" class="mt-3">
                        No KPI result available.
                    </v-alert>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn color="#003DA5" variant="flat" @click="showKpiDialog = false">Close</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </v-card-item>
</template>

<script setup>
import { computed, onBeforeMount, ref, watch } from 'vue';
import { useRouter } from 'vue-router';

const datasets = ref([]);
const isLoadingDatasets = ref(false);
const datasetErrorMessage = ref(null);
const showKpiDialog = ref(false);
const selectedDatasetForKpi = ref(null);
const isLoadingKpi = ref(false);
const kpiErrorMessage = ref(null);
const kpiResult = ref(null);
const isLoadingDatasetKpis = ref(false);
const isLoadingOtherDatasets = ref(false);
const datasetKpiById = ref({});
const selectedCentreId = ref(null);
const loadedCentreIds = ref({});
const loadedOtherCentreIds = ref({});
const gdcDatasetsByCentre = ref({});
const router = useRouter();

const GDC_LABEL_TO_BASE_URL = Object.freeze({
    DEV: 'https://gdc.wis2dev.io',
    DWD: 'https://wis2.dwd.de/gdc',
    CMA: 'https://gdc.wis.cma.cn/api',
    ECCC: 'https://wis2-gdc.weather.gc.ca'
});
const GDC_SOURCES = Object.entries(GDC_LABEL_TO_BASE_URL).map(([label, baseUrl]) => ({ label, baseUrl }));
const datasetPresenceByGdc = ref({});
const gdcRequestsInFlight = ref({});

const oapiBaseUrl = `${import.meta.env.VITE_API_URL}`.replace(/\/$/, '');

const sortDatasetsById = (items) => {
    return items.slice().sort((a, b) => (a.id || '').localeCompare(b.id || '', undefined, { sensitivity: 'base' }));
};

const extractCentreId = (identifier) => {
    if (typeof identifier !== 'string' || !identifier) {
        return 'unknown';
    }

    const segments = identifier.split(':');
    if (segments.length < 5 || segments[0] !== 'urn' || segments[1] !== 'wmo' || segments[2] !== 'md') {
        return 'unknown';
    }

    return segments[3] || 'unknown';
};

const datasetsByCentre = computed(() => {
    const grouped = new Map();

    datasets.value.forEach((dataset) => {
        const centreId = extractCentreId(dataset.id);

        if (!grouped.has(centreId)) {
            grouped.set(centreId, []);
        }

        grouped.get(centreId).push(dataset);
    });

    return Array.from(grouped.entries())
        .sort(([centreA], [centreB]) => centreA.localeCompare(centreB, undefined, { sensitivity: 'base' }))
        .map(([centreId, centreDatasets]) => ({
            centreId,
            datasets: centreDatasets
        }));
});

const centreIds = computed(() => datasetsByCentre.value.map((group) => group.centreId));

const centreIdOptions = computed(() => {
    return datasetsByCentre.value.map((group) => ({
        title: group.centreId,
        value: group.centreId
    }));
});

const selectedCentreDatasets = computed(() => {
    const selectedGroup = datasetsByCentre.value.find((group) => group.centreId === selectedCentreId.value);
    return selectedGroup?.datasets || [];
});

const selectedLocalDatasetIdSet = computed(() => {
    return new Set(selectedCentreDatasets.value.map((dataset) => dataset.id));
});

const selectedOtherDatasets = computed(() => {
    const centreId = selectedCentreId.value;
    if (!centreId) {
        return [];
    }

    const centreDatasets = gdcDatasetsByCentre.value[centreId] || [];
    return centreDatasets.filter((dataset) => !selectedLocalDatasetIdSet.value.has(dataset.id));
});

const fetchDatasets = async () => {
    isLoadingDatasets.value = true;
    datasetErrorMessage.value = null;

    const datasetUrl = `${oapiBaseUrl}/collections/discovery-metadata/items?f=json`;

    try {
        const response = await fetch(datasetUrl);
        if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
        }

        const data = await response.json();
        if (data.features) {
            datasets.value = sortDatasetsById(
                data.features
                    .filter((feature) => feature.id)
                    .map((feature) => ({
                        id: feature.id,
                        title: feature.properties?.title || '',
                        description: feature.properties?.description || ''
                    }))
            );
        } else {
            datasets.value = [];
        }
    } catch (error) {
        datasetErrorMessage.value = 'Error fetching configured datasets, please check the API end point. See logs for more information.';
        console.error('Error fetching configured datasets:', error);
    } finally {
        isLoadingDatasets.value = false;
    }
};

const goToDatasetEditor = (dataset) => {
    router.push({
        name: 'DatasetEditorForm',
        query: { identifier: dataset.id }
    });
};

const formatPercentage = (value) => {
    if (value === null || value === undefined) {
        return 'N/A';
    }

    const parsed = Number(value);
    return Number.isNaN(parsed) ? 'N/A' : `${parsed.toFixed(1)}%`;
};

const formatComments = (comments) => {
    if (!Array.isArray(comments) || comments.length === 0) {
        return '';
    }

    return comments.join('\n');
};

const getDatasetKpiGrade = (datasetId) => {
    const summary = datasetKpiById.value[datasetId]?.summary;
    return summary?.grade ?? 'N/A';
};

const getDatasetKpiGradeClass = (datasetId) => {
    const grade = `${getDatasetKpiGrade(datasetId) || ''}`.trim().toUpperCase();

    if (grade === 'A') {
        return 'kpi-grade-a';
    }

    if (grade === 'B' || grade === 'C') {
        return 'kpi-grade-bc';
    }

    if (grade === 'N/A' || grade === '') {
        return 'kpi-grade-na';
    }

    return 'kpi-grade-other';
};

const getDatasetGdcStatus = (datasetId, label) => {
    return datasetPresenceByGdc.value[datasetId]?.[label] ?? null;
};

const getDatasetGdcBadges = (datasetId) => {
    return GDC_SOURCES
        .map(({ label }) => ({
            label,
            found: getDatasetGdcStatus(datasetId, label)
        }))
        .filter((badge) => {
            if (badge.label === 'DEV') {
                return badge.found === true;
            }

            // For non-DEV sources, only show once status is known.
            return badge.found === true || badge.found === false;
        });
};

const getGdcBadgeClass = (found) => {
    if (found === true) {
        return 'gdc-badge-found';
    }
    if (found === false) {
        return 'gdc-badge-missing';
    }
    return 'gdc-badge-pending';
};

const getGdcBadgeHoverText = (label, found) => {
    if (found === true) {
        return `Dataset found in GDC-${label}`;
    }
    if (found === false) {
        return `Dataset not found in GDC-${label}`;
    }
    return `Checking dataset in GDC-${label}`;
};

const isDatasetIdInCentreNamespace = (datasetId, centreId) => {
    if (typeof datasetId !== 'string' || !datasetId || !centreId) {
        return false;
    }

    const expectedPrefix = `urn:wmo:md:${centreId}:`;
    return datasetId.startsWith(expectedPrefix) && extractCentreId(datasetId) === centreId;
};

const buildGdcCentreQueryUrl = (baseUrl, centreId) => {
    const url = new URL(`${baseUrl}/collections/wis2-discovery-metadata/items`);
    // Keep quote-wrapped query to match expected GDC query behavior.
    url.searchParams.set('q', `"${centreId}"`);
    return url.toString();
};

const fetchGdcDatasetsForCentreFromSource = async (baseUrl, centreId) => {
    const response = await fetch(buildGdcCentreQueryUrl(baseUrl, centreId), {
        headers: {
            accept: 'application/json'
        }
    });

    if (!response.ok) {
        throw new Error(`Failed to query GDC datasets (${response.status}).`);
    }

    const data = await response.json();
    const features = Array.isArray(data?.features) ? data.features : [];
    return features
        .filter((feature) => isDatasetIdInCentreNamespace(feature?.id, centreId))
        .map((feature) => ({
            id: feature.id,
            title: feature.properties?.title || '',
            description: feature.properties?.description || ''
        }));
};

const loadOtherDatasetsForCentre = async (centreId) => {
    if (!centreId || loadedOtherCentreIds.value[centreId]) {
        return;
    }

    isLoadingOtherDatasets.value = true;

    try {
        const mergedById = new Map();

        for (const { baseUrl } of GDC_SOURCES) {
            try {
                const sourceDatasets = await fetchGdcDatasetsForCentreFromSource(baseUrl, centreId);
                sourceDatasets.forEach((dataset) => {
                    if (!mergedById.has(dataset.id)) {
                        mergedById.set(dataset.id, dataset);
                    }
                });
            } catch (error) {
                console.error(`Error loading other datasets for centre ${centreId} from ${baseUrl}:`, error);
            }
        }

        const mergedDatasets = sortDatasetsById(Array.from(mergedById.values()));

        gdcDatasetsByCentre.value = {
            ...gdcDatasetsByCentre.value,
            [centreId]: mergedDatasets
        };

        loadedOtherCentreIds.value = {
            ...loadedOtherCentreIds.value,
            [centreId]: true
        };

        await Promise.all(mergedDatasets.map((dataset) => ensureDatasetGdcPresence(dataset.id)));
    } finally {
        isLoadingOtherDatasets.value = false;
    }
};

const buildGdcItemUrl = (baseUrl, datasetId) => {
    return `${baseUrl}/collections/wis2-discovery-metadata/items/${encodeURIComponent(datasetId)}`;
};

const checkDatasetPresenceInGdc = async (baseUrl, datasetId) => {
    const response = await fetch(buildGdcItemUrl(baseUrl, datasetId), {
        headers: {
            accept: 'application/json'
        }
    });

    return response.status !== 404;
};

const ensureDatasetGdcPresence = async (datasetId) => {
    if (!datasetId || gdcRequestsInFlight.value[datasetId]) {
        return;
    }

    const existingStatus = datasetPresenceByGdc.value[datasetId];
    const hasAllStatuses = existingStatus
        && GDC_SOURCES.every(({ label }) => existingStatus[label] === true || existingStatus[label] === false);
    if (hasAllStatuses) {
        return;
    }

    gdcRequestsInFlight.value = {
        ...gdcRequestsInFlight.value,
        [datasetId]: true
    };

    const currentStatus = {
        ...(datasetPresenceByGdc.value[datasetId] || {})
    };

    for (const { label, baseUrl } of GDC_SOURCES) {
        try {
            currentStatus[label] = await checkDatasetPresenceInGdc(baseUrl, datasetId);
        } catch (error) {
            console.error(`Error checking GDC presence for ${label}:`, error);
            currentStatus[label] = false;
        }
    }

    datasetPresenceByGdc.value = {
        ...datasetPresenceByGdc.value,
        [datasetId]: currentStatus
    };

    const nextInFlight = { ...gdcRequestsInFlight.value };
    delete nextInFlight[datasetId];
    gdcRequestsInFlight.value = nextInFlight;
};

const loadGdcPresenceForCentre = async (centreId) => {
    if (!centreId) {
        return;
    }

    const targetDatasets = datasetsByCentre.value.find((group) => group.centreId === centreId)?.datasets || [];
    if (!targetDatasets.length) {
        return;
    }

    await Promise.all(targetDatasets.map((dataset) => ensureDatasetGdcPresence(dataset.id)));
};

const fetchDatasetMetadata = async (datasetId) => {
    const itemUrl = `${oapiBaseUrl}/../data/metadata/${encodeURIComponent(datasetId)}.json?f=json`;
    const response = await fetch(itemUrl, {
        headers: {
            accept: 'application/json'
        }
    });

    if (!response.ok) {
        throw new Error(`Failed to retrieve metadata record (${response.status}).`);
    }

    return response.json();
};

const executeKpiProcess = async (record) => {
    const executionUrl = `${oapiBaseUrl}/processes/pywcmp-wis2-wcmp2-kpi/execution`;
    const response = await fetch(executionUrl, {
        method: 'POST',
        headers: {
            accept: 'application/json',
            Prefer: 'respond-sync',
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            inputs: {
                record
            }
        })
    });

    if (!response.ok) {
        throw new Error(`Failed to execute metadata KPI process (${response.status}).`);
    }

    return response.json();
};

const fetchMetadataKpiResult = async (datasetId) => {
    const metadataRecord = await fetchDatasetMetadata(datasetId);
    return executeKpiProcess(metadataRecord);
};

const loadDatasetKpisForCentre = async (centreId) => {
    if (!centreId || loadedCentreIds.value[centreId]) {
        return;
    }

    const targetDatasets = datasetsByCentre.value.find((group) => group.centreId === centreId)?.datasets || [];
    if (!targetDatasets.length) {
        loadedCentreIds.value = {
            ...loadedCentreIds.value,
            [centreId]: true
        };
        return;
    }

    isLoadingDatasetKpis.value = true;

    try {
        const results = await Promise.allSettled(
            targetDatasets.map(async (dataset) => {
                const result = await fetchMetadataKpiResult(dataset.id);
                return { id: dataset.id, result };
            })
        );

        const nextKpiById = { ...datasetKpiById.value };
        results.forEach((item) => {
            if (item.status === 'fulfilled') {
                nextKpiById[item.value.id] = item.value.result;
            }
        });

        datasetKpiById.value = nextKpiById;
        loadedCentreIds.value = {
            ...loadedCentreIds.value,
            [centreId]: true
        };
    } catch (error) {
        console.error('Unexpected error while loading dataset KPI results:', error);
    } finally {
        isLoadingDatasetKpis.value = false;
    }
};

const loadMetadataKpi = async (datasetId) => {
    isLoadingKpi.value = true;
    kpiErrorMessage.value = null;
    kpiResult.value = null;

    try {
        const result = await fetchMetadataKpiResult(datasetId);
        kpiResult.value = result;
        datasetKpiById.value = {
            ...datasetKpiById.value,
            [datasetId]: result
        };
    } catch (error) {
        console.error('Error retrieving metadata KPI:', error);
        kpiErrorMessage.value = error?.message || 'Unable to retrieve metadata KPI.';
    } finally {
        isLoadingKpi.value = false;
    }
};

const showMetadataKpi = async (dataset) => {
    selectedDatasetForKpi.value = dataset;
    showKpiDialog.value = true;

    if (datasetKpiById.value[dataset.id]) {
        kpiErrorMessage.value = null;
        kpiResult.value = datasetKpiById.value[dataset.id];
        return;
    }

    await loadMetadataKpi(dataset.id);
};

onBeforeMount(async () => {
    await fetchDatasets();

    if (centreIds.value.length) {
        selectedCentreId.value = centreIds.value[0];
    }
});

watch(selectedCentreId, async (centreId) => {
    await loadDatasetKpisForCentre(centreId);
    await loadGdcPresenceForCentre(centreId);
    await loadOtherDatasetsForCentre(centreId);
});
</script>

<style scoped>
.overview-header-row {
    display: flex;
    align-items: flex-start;
    gap: 12px;
}

.centre-selector-inline {
    width: 240px;
    margin-top: 2px;
}

.centre-group:first-of-type {
    margin-top: 8px;
}

.dataset-list {
    background-color: #ffffff;
    padding: 4px;
    border-radius: 4px;
    border: 1px solid #dce3ec;
}

.other-dataset-list {
    background-color: #ffffff;
    padding: 4px;
    border-radius: 4px;
    border: 1px solid #dce3ec;
}

.dataset-item {
    background-color: #ffffff;
    border: 2px solid #c7d1e0;
    border-radius: 8px;
    box-shadow: none;
}

.dataset-list :deep(.v-list-item),
.other-dataset-list :deep(.v-list-item) {
    margin-bottom: 8px;
}

.dataset-list :deep(.v-list-item:last-child),
.other-dataset-list :deep(.v-list-item:last-child) {
    margin-bottom: 0;
}

.other-dataset-item :deep(.v-list-item-title),
.other-dataset-item :deep(.v-list-item-subtitle) {
    color: #9e1616 !important;
}

.dataset-item-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 8px;
}

.dataset-gdc-badges {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    justify-content: flex-end;
}

.gdc-badge {
    display: inline-block;
    min-width: 44px;
    text-align: center;
    border-radius: 999px;
    padding: 2px 10px;
    font-size: 0.75rem;
    font-weight: 700;
    color: #ffffff;
}

.gdc-badge-found {
    background-color: #2e7d32;
}

.gdc-badge-missing {
    background-color: #c62828;
}

.gdc-badge-pending {
    background-color: #6b7280;
}

.kpi-grade-row {
    display: flex;
    align-items: center;
    gap: 8px;
    flex-wrap: wrap;
}

.kpi-grade-label {
    font-size: 0.92rem;
    color: #4b5563;
}

.kpi-grade-badge {
    display: inline-block;
    min-width: 32px;
    text-align: center;
    border-radius: 999px;
    padding: 2px 10px;
    font-weight: 700;
    font-size: 0.86rem;
    color: #ffffff;
}

.kpi-grade-a {
    background-color: #2e7d32;
}

.kpi-grade-bc {
    background-color: #ef6c00;
}

.kpi-grade-other {
    background-color: #c62828;
}

.kpi-grade-na {
    background-color: #6b7280;
}

.kpi-comments-cell {
    white-space: pre-line;
}
</style>
