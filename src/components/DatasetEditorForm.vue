<template>
    <v-row class="justify-center">
        <v-col cols="12" class="max-dashboard-width">
            <v-card-title class="big-title">Dataset Editor Form</v-card-title>
            <v-card>
                <!-- Toolbar for user to select a dataset -->
                <v-toolbar color="#003DA5">
                    <v-toolbar-title>Please choose a dataset</v-toolbar-title>
                    <v-select class="mt-11" label="Dataset" v-model="identifier" :items="items"
                        @update:modelValue="loadMetadata" variant="underlined"></v-select>
                </v-toolbar>

                <!-- Until loaded, play a loading animation -->
                <v-progress-linear indeterminate color="primary" :active="working" />

                <!-- Dialog window -->
                <v-dialog v-model="showInitialDialog" max-width="600px" persistent>
                    <v-card>
                        <v-card-title>
                            New dataset: Initial Information
                            <v-btn icon="mdi-comment-question" variant="text" size="small"
                                @click="openInitialHelpDialog = true" />
                        </v-card-title>
                        <v-card-text>
                            <v-checkbox v-model="isNonRealTime" label="Publish metadata without WIS2 data notifications" color="#003DA5" />
                            <v-row>
                                <v-col cols="12">
                                    <v-combobox v-model="model.identification.centreID" :items="centreList"
                                    label="Centre ID" :rules="[rules.centreID]" variant="outlined" @update:modelValue="convertToLowercase"></v-combobox>
                                </v-col>
                            </v-row>
                            <v-select v-model="selectedTemplate" :items="templateFiles" item-title="label" return-object
                                        label="Template" variant="outlined"  :disabled="isNonRealTime" v-if="!isNonRealTime">
                            </v-select>
                        </v-card-text>
                        <v-card-actions>
                            <v-col cols="12">
                                <v-row>
                                    <v-col cols="6">
                                        <v-btn color="#009900" append-icon="mdi-home" variant="flat" block
                                            @click="redirectUser">Return Home</v-btn>
                                    </v-col>
                                    <v-col cols="6">
                                        <v-btn color="#003DA5" append-icon="mdi-form-select" variant="flat" block
                                            @click="continueToForm" :disabled="!initialDialogFilled">Continue to
                                            Form</v-btn>
                                    </v-col>
                                </v-row>
                            </v-col>
                        </v-card-actions>
                    </v-card>
                </v-dialog>

                <!-- Display messages to the user -->
                <v-col cols="12">
                    <v-row align="center">
                        <v-col cols="4">
                            <h4>{{ message }}</h4>
                        </v-col>
                        <v-col cols="4" />
                        <v-col cols="4">
                            <v-btn v-if="datasetIsBeingUpdated" color="error" class="ma-2"
                                @click="openRemoveConfirmationDialog = true" append-icon="mdi-delete" block>
                                Remove Dataset From Collection
                            </v-btn>
                        </v-col>
                    </v-row>
                </v-col>
            </v-card>

            <!-- Dialog to confirm the removal of the dataset
            from the collection, by the user entering the
            authentication token -->
            <v-dialog v-model="openRemoveConfirmationDialog" max-width="600px">
                <v-card>
                    <v-toolbar title="Confirm Removal of Dataset" color="error">
                        <v-btn icon="mdi-close" variant="text" size="small"
                            @click="openRemoveConfirmationDialog = false" />
                    </v-toolbar>
                    <v-card-text>
                        To confirm that you want to remove
                        this dataset from the collection,
                        please enter your authentication token.
                    </v-card-text>
                    <v-container>
                        <v-text-field label="wis2box auth token for 'processes/wis2box'" v-model="token" rows="1"
                            :append-icon="showToken ? 'mdi-eye' : 'mdi-eye-off'" :type="showToken ? 'text' : 'password'" autocomplete="one-time-code"
                            @click:append="showToken = !showToken" :rules="[rules.token]" variant="outlined">
                        </v-text-field>
                    </v-container>
                    <v-card-actions>
                        <v-btn color="error" block variant="flat" @click="removeDataset"
                            :disabled="!token">Remove</v-btn>
                    </v-card-actions>
                </v-card>
            </v-dialog>

            <!-- Metadata Editor -->
            <v-card v-if="metadataLoaded" class="mt-6 pa-3" style="overflow: initial; z-index: initial">
                <v-card-title class="big-title">Metadata Editor</v-card-title>
                <v-card-subtitle v-if="isNonRealTime">
                    Metadata record for dataset without WIS2 data notifications
                </v-card-subtitle>
                <!-- Form which when filled and validated, can be exported or submitted -->
                <v-form v-model="formFilled" ref="formRef">
                    <!-- Identification section -->
                    <v-card-title>
                        Dataset Identification
                        <v-btn icon="mdi-comment-question" variant="text" size="small"
                            @click="openIdentificationHelpDialog = true" />
                    </v-card-title>
                    <v-row>
                        <v-col cols="6">
                            <v-row dense>
                                <v-col cols="12">
                                    <v-text-field label="Title" type="string" v-model="model.identification.title"
                                        :rules="[rules.required]" variant="outlined" clearable></v-text-field>
                                </v-col>
                            </v-row>
                            <v-row dense>
                                <v-col cols="12">
                                    <v-text-field label="Local ID" type="string" v-model="localID" @input="updateIdentifierFromLocalID" variant="outlined" @update:modelValue="convertToLowercaseLocalID" clearable :disabled="isEditing"></v-text-field>
                                </v-col>
                            </v-row>
                        </v-col>

                        <v-col cols="6">
                            <v-textarea label="Description"
                                placeholder="Please enter a detailed description of the dataset" type="string"
                                v-model="model.identification.description" :rules="[rules.required]" variant="outlined"
                                clearable></v-textarea>
                        </v-col>

                        <v-col cols="12">
                            <v-row dense>
                                <v-col cols="11">
                                    <v-text-field label="Identifier" type="string"
                                        v-model="model.identification.identifier"
                                        disabled  variant="outlined">
                                    </v-text-field>
                                </v-col>
                                <v-col cols="1">    
                                    <v-btn icon @click="copyIdentifier" 
                                    aria-label="Copy Identifier">
                                    <v-icon>mdi-content-copy</v-icon>
                                    </v-btn>
                                </v-col>
                            </v-row>
                        </v-col>
                    </v-row>
                    <v-row>
                    </v-row>
                    <v-row>
                        <v-col cols="4">
                            <v-text-field label="Centre ID" type="string" v-model="model.identification.centreID"
                                variant="outlined" clearable disabled></v-text-field>
                        </v-col>
                        <v-col cols="4">
                            <v-select label="WMO Data Policy" type="string" :items="['core', 'recommended']"
                                v-model="model.identification.wmoDataPolicy" :rules="[rules.required]"
                                variant="outlined" :disabled="!isNew"></v-select>
                        </v-col>
                        <v-col cols="4" v-if="isNonRealTime === false">
                            <v-select label="Discipline topic"
                                :items="earthSystemDisciplines" item-title="name" item-value="name"
                                v-model="model.identification.subTopic1" :rules="[rules.required]"
                                variant="outlined" :disabled="!isNew || selectedTemplate?.label !== 'other'"></v-select>
                        </v-col>
                    </v-row>
                    <v-row v-if="model.identification.wmoDataPolicy === 'recommended'">           
                        <v-col cols="8" v-if="model.identification.isCustomLicense">
                            <v-text-field 
                                label="License (provide valid URL)" 
                                type="url" 
                                v-model="model.identification.licenseLink" 
                                :rules="[rules.url]" 
                                variant="outlined" 
                                clearable>
                            </v-text-field>
                        </v-col>
                        <v-col cols="8" v-else>
                            <v-select 
                                label="License (choose one)" 
                                :items="license_options"
                                item-title="label" 
                                item-value="value"
                                v-model="model.identification.licenseLink"
                                :rules="[rules.required]"
                                variant="outlined">
                            </v-select>
                        </v-col>
                        <v-col cols="4">
                            <v-checkbox v-model="model.identification.isCustomLicense" 
                            label="custom license (provide your own link)"
                            variant="outlined" :disabled="true" :value="true"></v-checkbox>
                        </v-col>
                    </v-row>
                    <v-row v-if="isNonRealTime === false">
                        <!-- toggle between selection sub-discipline topics and free-text input -->
                        <v-col cols="8" v-if="!model.identification.isExperimental">
                            <v-autocomplete label="Sub-discipline topics (choose one)"
                            :items="subTopics2" item-title="description"
                            v-model="model.identification.subTopic2" :rules="[rules.required]"
                            variant="outlined" :disabled="!isNew || selectedTemplate?.label !== 'other'"></v-autocomplete>
                        </v-col>
                        <v-col cols="8" v-else>
                            <v-text-field label="Sub-discipline topics (free-text)" type="string"
                            v-model="model.identification.subTopic2" :rules="[rules.required]"
                            variant="outlined" clearable></v-text-field>
                        </v-col>
                        <v-col cols="4">
                            <v-checkbox v-model="model.identification.isExperimental" 
                            label="experimental (free-text topic)"
                            variant="outlined" :disabled="!isNew || selectedTemplate?.label !== 'other'"></v-checkbox>
                        </v-col>
                    </v-row>
                    <v-row v-if="isNonRealTime === false">
                        <!-- the field topicHierarchy should be updated based on the selection of sub-topic -->
                        <v-col cols="12">
                            <v-text-field label="Topic Hierarchy" type="string"
                                v-model="model.identification.topicHierarchy" :rules="[rules.required]"
                                item-title="description" item-value="value"
                                variant="outlined" disabled></v-text-field>
                        </v-col>
                    </v-row>
                    <v-row>
                        <v-col cols="4">
                            <v-select label="Earth System Disciplines" v-model="model.identification.concepts" multiple
                                :items="earthSystemDisciplines" item-title="name" item-value="name"
                                variant="outlined"></v-select>
                        </v-col>
                        <v-col cols="8">
                            <v-row dense>
                                <v-col cols="4">
                                    <v-text-field label="Keywords (3 minimum)" type="array" v-model="keyword"
                                        @keyup.enter="addKeyword" variant="outlined" clearable
                                        :rules="[rules.keywords]"></v-text-field>
                                </v-col>
                                <v-col cols="1">
                                    <v-btn color="#003DA5" variant="flat" icon="mdi-plus" size="large"
                                        @click="addKeyword" :disabled="keyword === ''"></v-btn>
                                </v-col>
                                <v-col cols="7">
                                    <v-chip-group>
                                        <v-chip v-for="keyword in model.identification.keywords" :key="keyword" closable
                                            label @click:close="removeKeyword(keyword)">
                                            {{ keyword }}
                                        </v-chip>
                                    </v-chip-group>
                                </v-col>
                            </v-row>
                        </v-col>
                    </v-row>

                    <v-card-title class="big-title" v-if="isNonRealTime">
                        Data-access links
                        <v-btn icon="mdi-comment-question" variant="text" size="small"
                            @click="openLinkHelpDialog = true" />
                    </v-card-title>
                    <v-container v-if="isNonRealTime">
                        <p v-if="model.links?.length > 0">Data-access links:</p>
                        <p v-else>No data-access links are currently associated with this dataset</p>
                        <v-table :hover="true" >
                            <thead>
                                <tr>
                                    <th scope="row">Title</th>
                                    <th scope="row">URL</th>
                                    <th scope="row">rel</th>
                                    <th scope="row" class="text-right"></th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="link in model.links" :key="link.href" @click="viewLink(link)"
                                    class="clickable-row">
                                    <td class="medium-title">
                                        {{ link.title }}
                                    </td>
                                    <td class="medium-title">
                                        {{ link.href }}
                                    </td>
                                    <td class="medium-title">
                                        {{ link.rel }}
                                    </td>
                                    <td class="text-right">
                                        <v-btn class="mr-5" append-icon="mdi-update" color="#003DA5" variant="flat"
                                            @click.stop="configureLink(link)">
                                            Update
                                        </v-btn>
                                        <v-btn append-icon="mdi-delete" color="error" variant="flat"
                                            @click.stop="removeLink(link)">Delete</v-btn>
                                    </td>
                                </tr>
                            </tbody>
                        </v-table>
                    </v-container>
                    <v-row justify="center" class="mt-1" v-if="isNonRealTime">
                        <v-col cols="8">
                            <v-btn @click="configureLink()" append-icon="mdi-plus" color="#64BF40" block>Add A
                                Link</v-btn>
                        </v-col>
                    </v-row>
                    <v-row>
                    </v-row>
                    <v-card-title>
                        Temporal Properties
                        <v-btn icon="mdi-comment-question" variant="text" size="small"
                            @click="openTemporalHelpDialog = true" />
                    </v-card-title>
                    <v-row>
                        <v-col cols="3">
                            <VueDatePicker placeholder="Begin Date in UTC" v-model="model.extents.dateStarted"
                                :teleport="true" :enable-time-picker="false" format="yyyy-MM-dd" auto-apply required />
                            <p v-if="model.extents.dateStarted === null" class="hint-text hint-invalid">Start date is required</p>
                        </v-col>
                        <v-col cols="3" v-if="!isEndDateDisabled">
                            <VueDatePicker placeholder="End Date in UTC" v-model="model.extents.dateStopped"
                                :teleport="true" :enable-time-picker="false" format="yyyy-MM-dd"
                                :disabled="isEndDateDisabled" :state="endDatePossible" auto-apply required />
                            <p v-if="endDatePossible === false" class="hint-text hint-invalid">End date cannot be before
                                the start date!
                            </p>
                        </v-col>
                        <v-col cols="2" v-if="!isNonRealTime">
                            <v-checkbox v-model="isEndDateDisabled" label="Dataset ongoing" color="#003DA5" :disabled="isNonRealTime"/>
                        </v-col>
                        <v-col cols="4">
                            <v-row dense>
                                <v-col cols="5">
                                    <v-text-field label="Resolution" type="string" v-model="model.extents.resolution"
                                        variant="outlined" clearable></v-text-field>
                                </v-col>
                                <v-col cols="5">
                                    <v-select label="Unit" :items="durations" item-title="name" item-value="code"
                                        v-model="model.extents.resolutionUnit"
                                        variant="outlined" clearable></v-select>
                                </v-col>
                            </v-row>
                        </v-col>
                    </v-row>
                    <v-card-title>
                        Spatial Properties
                        <v-btn icon="mdi-comment-question" variant="text" size="small"
                            @click="openSpatialHelpDialog = true" />
                    </v-card-title>
                    <v-row dense>
                        <v-col cols="5">
                            <v-row>
                                <v-col cols="12">
                                    <!-- Allow the user to select a country different to that of the host for the auto bbox -->
                                    <v-autocomplete label="Choose an automatic bounding box (optional)"
                                        item-title="name" item-value="alpha-3" :items="filteredCountryCodeList"
                                        v-model="bboxCountry" @update:modelValue="getAutoBbox(bboxCountry)"
                                        hint="Your country may not have an automatic bounding box" persistent-hint
                                        variant="outlined"></v-autocomplete>
                                </v-col>
                            </v-row>
                            <v-row class="row-spacer" />
                            <v-row class="coordinate-rows">
                                <v-col cols="4" />
                                <v-col cols="4">
                                    <v-text-field label="North Latitude" type="number"
                                        v-model.number="model.extents.northLatitude"
                                        :rules="[rules.required, rules.latitude]" variant="outlined"
                                        clearable></v-text-field>
                                </v-col>
                                <v-col cols="4" />
                            </v-row>
                            <v-row class="coordinate-rows">
                                <v-col cols="4">
                                    <v-text-field label="West Longitude" type="number"
                                        v-model.number="model.extents.westLongitude"
                                        :rules="[rules.required, rules.longitude]" variant="outlined"
                                        clearable></v-text-field>
                                </v-col>
                                <v-col cols="4" />
                                <v-col cols="4">
                                    <v-text-field label="East Longitude" type="number"
                                        v-model.number="model.extents.eastLongitude"
                                        :rules="[rules.required, rules.longitude]" variant="outlined"
                                        clearable></v-text-field>
                                </v-col>
                            </v-row>
                            <v-row>
                                <v-col cols="4" />
                                <v-col cols="4">
                                    <v-text-field label="South Latitude" type="number"
                                        v-model.number="model.extents.southLatitude"
                                        :rules="[rules.required, rules.latitude]" variant="outlined"
                                        clearable></v-text-field>
                                </v-col>
                                <v-col cols="4" />
                            </v-row>
                        </v-col>
                        <v-col cols="7">
                            <!-- Bounding box editor -->
                            <bbox-editor :box-bounds="bounds" id="bbox-editor"></bbox-editor>
                        </v-col>
                    </v-row>

                    <!-- Contact (host) section -->
                    <v-card-title>
                        Contact Information of the Data Provider
                        <v-btn icon="mdi-comment-question" variant="text" size="small"
                            @click="openHostHelpDialog = true" />
                    </v-card-title>
                    <v-row>
                        <v-col cols="4">
                            <v-text-field label="Organization Name" type="string" v-model="model.host.name"
                                :rules="[rules.required]" variant="outlined" clearable></v-text-field>
                        </v-col>
                        <v-col cols="4">
                            <v-text-field label="URL" hint="Organization website" type="string" v-model="model.host.url"
                                :rules="[rules.url]" variant="outlined" clearable></v-text-field>
                        </v-col>
                        <v-col cols="4">
                            <!-- The host country is disabled as it was selected
                            already in the dialog -->
                            <v-autocomplete label="Country" item-title="name" item-value="alpha-3"
                                :items="countryCodeList" v-model="model.host.country" :rules="[rules.required]"
                                variant="outlined"></v-autocomplete>
                        </v-col>
                    </v-row>
                    <v-row>
                        <v-col cols="4">
                            <v-text-field label="Email" type="string" v-model="model.host.email"
                                :rules="[rules.required, rules.email]" variant="outlined" clearable></v-text-field>
                        </v-col>
                        <v-col cols="4">
                            <vue-tel-input v-model="model.host.phone" @validate="onHostPhoneValidate"
                                required></vue-tel-input>
                            <p v-if="(typeof isHostPhoneValid !== 'undefined') && !isHostPhoneValid"
                                class="hint-text hint-invalid">Phone number is not valid</p>
                        </v-col>
                    </v-row>
                    <v-col cols="12">
                        <v-row>
                            <v-col cols="6">
                                <v-btn @click="resetForm" append-icon="mdi-sync" block color="#1FB5DB">
                                    Reset Form
                                </v-btn>
                            </v-col>
                            <v-col cols="6">
                                <v-btn @click="validateForm" append-icon="mdi-shield-check" block color="#003DA5"
                                    :disabled="!formUpdated">
                                    Validate Form
                                </v-btn>
                            </v-col>
                        </v-row>
                    </v-col>
                </v-form>
            </v-card>

            <!-- Dataset Mappings Editor -->
            <v-card v-if="metadataLoaded && !isNonRealTime" class="mt-16 pa-3">
                <v-card-title class="big-title">
                    Dataset Mappings Editor
                    <v-btn icon="mdi-comment-question" variant="text" size="small"
                        @click="openPluginHelpDialog = true" />
                </v-card-title>
                <v-container>
                    <v-table v-if="canShowPluginTable" :hover="true">
                        <thead>
                            <tr>
                                <th scope="row">
                                    <p v-if="model.plugins?.length > 0">Plugins in use</p>
                                    <p v-else>No plugins are currently associated with this dataset</p>
                                </th>
                                <th scope="row">File extension</th>
                                <th scope="row">File pattern</th>
                                <th scope="row" class="text-right"></th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="plugin in model.plugins" :key="plugin.name" @click="viewPlugin(plugin)"
                                class="clickable-row">
                                <td class="medium-title">
                                    {{ getPluginTitle(plugin) }}
                                </td>
                                <td class="medium-title">
                                    {{ plugin.fileType }}
                                </td>
                                <td class="medium-title">
                                    {{ plugin.filePattern }}
                                </td>
                                <td class="text-right">
                                    <v-btn class="mr-5" append-icon="mdi-update" color="#003DA5" variant="flat"
                                        @click.stop="configurePlugin(plugin)">
                                        Update
                                    </v-btn>
                                    <v-btn append-icon="mdi-delete" color="error" variant="flat"
                                        @click.stop="removePlugin(plugin)">Delete</v-btn>
                                </td>
                            </tr>
                        </tbody>
                    </v-table>
                </v-container>
                <v-row justify="center" class="mt-1">
                    <v-col cols="8">
                        <v-btn @click="configurePlugin()" append-icon="mdi-plus" color="#64BF40" block>Add A
                            Plugin</v-btn>
                    </v-col>
                </v-row>
            </v-card>

            <!-- Authentication token section -->
            <v-card class="mt-16 pa-3" v-if="metadataLoaded">
                <v-card-title>Authentication Token
                    <v-btn icon="mdi-comment-question" variant="text" size="small"
                        @click="openTokenHelpDialog = true" />
                </v-card-title>
                <v-card-text>
                    <v-text-field label="wis2box auth token for 'processes/wis2box'" v-model="token" rows="1"
                        :append-icon="showToken ? 'mdi-eye' : 'mdi-eye-off'" :type="showToken ? 'text' : 'password'" autocomplete="one-time-code"
                        @click:append="showToken = !showToken" :rules="[rules.token]" variant="outlined">
                    </v-text-field>
                </v-card-text>
            </v-card>

            <!-- Toolbar for user to reset, validate, export, or submit the data
            from the above forms -->
            <v-col cols="12">
                <v-row class="pt-5" v-if="metadataLoaded">
                    <v-col cols="6">
                        <v-btn color="#E09D00" class="ma-2" title="Export" @click="downloadMetadata"
                            append-icon="mdi-arrow-down-bold-box-outline" block>
                            Export As JSON
                        </v-btn>
                    </v-col>
                    <v-col cols="6">
                        <v-btn color="#003DA5" class="ma-2" title="Submit" @click="verifyFormIsFilled"
                            append-icon="mdi-cloud-upload" block>
                            Submit
                        </v-btn>
                    </v-col>
                </v-row>
            </v-col>

            <!-- Help dialogs -->
            <v-dialog v-model="openInitialHelpDialog" max-width="600px">
                <v-card>
                    <v-toolbar title="Initial Information" color="#003DA5">
                        <v-btn icon="mdi-close" variant="text" size="small" @click="openInitialHelpDialog = false" />
                    </v-toolbar>
                    <v-card-subtitle>
                        What is this section for?
                    </v-card-subtitle>
                    <v-card-text>
                        <p>To begin creating a new dataset, we require some initial information in order to
                            pre-fill the form.</p>
                        <p><i>Note: use the checkbox if you wish to publish metadata without WIS2 data notifications (requires a data-access link to be provided). </i></p>
                        <br>
                        <p><b>Centre ID:</b> The agency acronym (in lower case and no spaces), as specified by
                            the WMO Member.</p>
                        <br>
                        <p><b>Template</b> For real-time data, you can select the type of data you are creating metadata for from a list of templates.
                            This ensures you are using the correct topic-hierarchy, along with suggestions for title and keywords and default data-mappings.
                            <br>
                            <i>If 'other' is
                                selected, you are responsible for ensuring the correct WIS2 Topic Hierarchy is used and you will need to define your own data-mappings.</i></p>
                        <br>
                        <br>
                    </v-card-text>
                </v-card>
            </v-dialog>
            <v-dialog v-model="openIdentificationHelpDialog" max-width="600px">
                <v-card>
                    <v-toolbar title="Dataset Identification" color="#003DA5">
                        <v-btn icon="mdi-close" variant="text" size="small"
                            @click="openIdentificationHelpDialog = false" />
                    </v-toolbar>
                    <v-card-subtitle>
                        How do I complete this section?
                    </v-card-subtitle>
                    <v-card-text>
                        <p><b>Title:</b> A human-readable name of the dataset.</p>
                        <p><i>Note: Unless 'other' was selected initially, this field is pre-filled, please review and update the title where necessary.</i></p>
                        <br>
                        <p><b>Description:</b> A free-text summary description of the dataset.</p>
                        <br>
                        <p><b>Local ID:</b> A short and unique identifier for the dataset within your organization.</p>
                        <p><i>Note: Local ID is used to generate the WCMP2 identifier for your metadata record.
                          Once the dataset is created, the identifier can no longer be updated. To use a
                                different Local ID you will need to delete and re-create the dataset.
                        </i></p>
                        <br>
                        <p><b>Identifier:</b> The unique identifier for your dataset in the WIS2 Global Discovery Catalogue, also known as the "metadata-id".
                          It should start with <b>urn:wmo:md</b>.
                          The dataset editor will automatically generate this identifier based on your centre-id and Local ID.
                        </p>
                        <br>
                        <p><b>Centre ID:</b> This is pre-filled and <i>cannot be edited</i>.</p>
                        <br>
                        <p><b>WMO Data Policy:</b> Classification code of core or recommended based on the WMO
                            Unified
                            Data
                            Policy.
                        </p>
                        <br>
                        <p><b>Discipline Topic:</b> 7th level of the Topic Hierarchy</p>
                        <p><b>Sub-discipline Topics:</b> Topic Hierarchy from the 8th level onwards, available options are based on the latest WIS2 Topic Hierarchy.</p>
                        <p><i>Note: use 'experimental' if the channel for your data is not yet available.</i></p>
                        <br>
                        <p><b>Topic Hierarchy:</b> MQTT channel used to publish data-notifications.
                            The dataset editor will automatically generate this based on your centre-id, data-policy and sub-topic selection</p>
                        <br>
                        <p><b>Earth System Disciplines:</b> A list of concepts that are referenced to a
                            vocabulary or
                            knowledge organization
                            system used to classify the resource.</p>
                        <br>
                        <p><b>Keywords:</b> A list of at least three keywords, tags or specific phrases
                            associated with
                            the
                            resource, but are not referenced to a particular vocabulary or knowledge
                            organization
                            system.
                        </p>
                        <br>
                        <p><b>License:</b>
                            <i>If you select 'recommended' as WMO Data Policy, you will be required to provide a license link.</i>
                            For new datasets, Creative Commons licenses offer standardized, widely-recognized terms that clearly communicate usage rights to others.
                            Visit the Creative Commons website to explore license options that match your sharing preferences.
                            Choose 'custom license' if you want to provide your own license link.
                        </p>
                        <br>
                    </v-card-text>
                </v-card>
            </v-dialog>
            <v-dialog v-model="openTemporalHelpDialog" max-width="600px">
                <v-card>
                    <v-toolbar title="Temporal Properties" color="#003DA5">
                        <v-btn icon="mdi-close" variant="text" size="small" @click="openTemporalHelpDialog = false" />
                    </v-toolbar>
                    <v-card-subtitle>
                        How do I complete this section?
                    </v-card-subtitle>
                    <v-card-text>
                        <p><b>Begin Date:</b> The date in UTC when the dataset begins.</p>
                        <br>
                        <p><b>End Date:</b> The date in UTC when the dataset ends.</p>
                        <br>
                        <p><b>Temporal Resolution (optional):</b> The smallest increment of time that is represented in the
                            dataset.
                        </p>
                        <p>This is split into two parts, the <b>value</b> (e.g. 1) and the <b>unit</b> (e.g.
                            'hour(s)').
                        </p>
                        <br>
                    </v-card-text>
                </v-card>
            </v-dialog>
            <v-dialog v-model="openSpatialHelpDialog" max-width="600px">
                <v-card>
                    <v-toolbar title="Spatial Properties" color="#003DA5">
                        <v-btn icon="mdi-close" variant="text" size="small" @click="openSpatialHelpDialog = false" />
                    </v-toolbar>
                    <v-card-subtitle>
                        How do I complete this section?
                    </v-card-subtitle>
                    <v-card-text>
                        <p>This section describes the general bounding spatial extent of the dataset in the
                            geographic
                            coordinate system. This can be created either:</p>
                        <br>
                        <p><b>Automatically:</b> By using the country dropdown (note that your country may not
                            be found
                            on
                            this list).</p>
                        <br>
                        <p><b>Manually:</b> By the entering the northmost, eastmost, southmost, and westmost
                            coordinates
                            of
                            the dataset.</p>
                        <br>
                        <p><i><b>Warning: The automatic bounding box created may be incorrect for the country,
                                    so please
                                    verify it before proceeding!</b></i></p>
                        <br>
                    </v-card-text>
                </v-card>
            </v-dialog>
            <v-dialog v-model="openHostHelpDialog" max-width="600px">
                <v-card>
                    <v-toolbar title="Contact Information of the Data Provider" color="#003DA5">
                        <v-btn icon="mdi-close" variant="text" size="small" @click="openHostHelpDialog = false" />
                    </v-toolbar>
                    <v-card-subtitle>
                        How do I complete this section?
                    </v-card-subtitle>
                    <v-card-text>
                        <p>This section provides the information associated with one or more responsible parties
                            of the
                            resource.</p>
                        <br>
                        <p><b>Organization Name:</b> The name of the contact's organization.</p>
                        <br>
                        <p><b>URL:</b> The URL to the contact's organization homepage, including the <i>http</i> or
                            <i>https</i>
                            prefix.
                        </p>
                        <br>
                        <p><b>Country:</b> The country of the contact.</p>
                        <br>
                        <p><b>Email:</b> The email address of the contact.</p>
                        <br>
                        <p><b>Phone Number (optional):</b> The phone number of the contact, written in
                            international
                            format (+).</p>
                    </v-card-text>
                </v-card>
            </v-dialog>

            <v-dialog v-model="openPluginHelpDialog" max-width="600px">
                <v-card>
                    <v-toolbar title="Data Mappings" color="#003DA5">
                        <v-btn icon="mdi-close" variant="text" size="small" @click="openPluginHelpDialog = false" />
                    </v-toolbar>
                    <v-card-subtitle>
                        What is this section for?
                    </v-card-subtitle>
                    <v-card-text>
                        <p>The data mappings define how the data that is uploaded to the "wis2box-incoming"-bucket is
                            processed before it is published.</p>
                        <br>
                        <p>To publish data without conversion, select Plugin Name = "Universal data without conversion".
                        </p>
                        <br>
                        <p><b>At least one plugin</b> needs to be associated with your dataset before proceeding.</p>
                        <br>
                        <p><i>For more information about Plugins see the wis2box documentation.</i></p>
                        <br>
                    </v-card-text>
                </v-card>
            </v-dialog>

            <v-dialog v-model="openLinkHelpDialog" max-width="600px">
                <v-card>
                    <v-toolbar title="Data-access links" color="#003DA5">
                        <v-btn icon="mdi-close" variant="text" size="small" @click="openLinkHelpDialog = false" />
                    </v-toolbar>
                    <v-card-subtitle>
                        What is this section for?
                    </v-card-subtitle>
                    <v-card-text>
                        <p>For datasets without WIS2 data notifications, the user should provide at least one link enabling data access.</p>
                        <br>
                        <p><b>Link URL:</b> URL to to a web-accessible folder (WAF) or an API-endpoint.</p>
                        <br>
                        <p><b>Link Description:</b> Brief link title to describe dataset type and content.</p>
                        <br>
                        <p><b>Link Type:</b> Online data archive (rel='archives') or OpenAPI endpoint (rel='service-desc')</p>
                    </v-card-text>
                </v-card>
            </v-dialog>

            <v-dialog v-model="openTokenHelpDialog" max-width="600px">
                <v-card>
                    <v-toolbar title="Authentication Token" color="#003DA5">
                        <v-btn icon="mdi-close" variant="text" size="small" @click="openTokenHelpDialog = false" />
                    </v-toolbar>
                    <v-card-subtitle>
                        What is this section for?
                    </v-card-subtitle>
                    <v-card-text>
                        <p>In order to submit this dataset to the wis2box, you must provide a valid authentication token
                            for the <b>processes/wis2box path</b>.</p>
                        <br>
                        <p><i>For information about creating authentication tokens, see the wis2box documentation.</i>
                        </p>
                        <br>
                    </v-card-text>
                </v-card>
            </v-dialog>

            <!-- Dialog to display typical informative messages -->
            <v-dialog v-model="openMessageDialog" max-width="600px" persistent>
                <v-card>
                    <v-toolbar title="Result" color="#003DA5">
                    </v-toolbar>
                    <v-card-text>
                        {{ message }}
                        <ul style="padding-left: 1rem;">
                            <li v-for="(issue, index) in submissionIssues" :key="index">{{ issue }}</li>
                        </ul>
                    </v-card-text>
                    <v-card-actions>
                        <v-btn color="#003DA5" variant="flat" block @click="resetMessage('typical')">
                            OK
                        </v-btn>
                    </v-card-actions>
                </v-card>
            </v-dialog>

            <!-- Dialog to display the validation outcome -->
            <!-- Dialog to display successful submission message -->
            <v-dialog v-model="openValidationDialog" max-width="600px" persistent>
                <v-card>
                    <v-toolbar title="Validation Outcome" :color="formValidated ? '#64BF40' : 'error'">
                    </v-toolbar>
                    <v-card-text>
                        {{ message }}
                    </v-card-text>
                    <v-card-actions>
                        <v-btn block variant="flat" @click="resetMessage('validation')" :color="formValidated ? '#64BF40' : 'error'">
                            OK
                        </v-btn>
                    </v-card-actions>
                </v-card>
            </v-dialog>

            <!-- Dialog to display successful submission message -->
            <v-dialog v-model="openSuccessDialog" max-width="600px" persistent>
                <v-card>
                    <v-toolbar title="Success" color="#64BF40">
                    </v-toolbar>
                    <v-card-text>
                        {{ message }}
                    </v-card-text>
                    <v-card-actions>
                        <v-btn color="#64BF40" block @click="redirectUser">
                            OK
                        </v-btn>
                    </v-card-actions>
                </v-card>
            </v-dialog>


            <!-- Dialog for the user to view a plugin -->
            <v-dialog v-model="openViewPluginDialog" max-width="600px">
                <v-card>
                    <v-toolbar title="Plugin Details" color="#003DA5">
                        <v-btn icon="mdi-close" variant="text" size="small" @click="openViewPluginDialog = false" />
                    </v-toolbar>
                    <v-card-item>
                        <v-table class="my-2">
                            <tbody>
                                <tr>
                                    <td><b>Plugin Name</b></td>
                                    <td>{{ pluginNameTitle }}</td>
                                </tr>
                                <tr>
                                    <td><b>File Extension</b></td>
                                    <td>{{ pluginFileExtension }}</td>
                                </tr>
                                <tr>
                                    <td><b>Template</b></td>
                                    <td>{{ pluginTemplateTitle }}</td>
                                </tr>
                                <tr>
                                    <td><b>WIS2 Buckets</b></td>
                                    <td>{{ pluginBucketsTitle }}</td>
                                </tr>
                                <tr>
                                    <td><b>File Pattern</b></td>
                                    <td>{{ pluginFilePattern }}</td>
                                </tr>
                            </tbody>
                        </v-table>
                    </v-card-item>
                </v-card>
            </v-dialog>

            <!-- Dialog for the user to configure plugins -->
            <v-dialog v-model="openConfigurePluginDialog" max-width="750px">
                <v-card>
                    <v-toolbar title="Plugin Configuration" color="#003DA5">
                        <v-btn icon="mdi-close" variant="text" size="small"
                            @click="openConfigurePluginDialog = false" />
                    </v-toolbar>
                    <v-container>
                        <v-col cols="12">
                            <v-row>
                                <v-col cols="8">
                                    <!-- Disable this if editing an existing plugin -->
                                    <v-select label="Plugin Name" v-model="pluginName" :items="pluginList"
                                        item-title="title" item-value="id" variant="outlined" :disabled="!pluginIsNew"></v-select>
                                </v-col>
                                <v-col cols="4">
                                    <v-text-field label="File Extension" v-model="pluginFileExtension"
                                        variant="outlined"></v-text-field>
                                </v-col>
                            </v-row>

                            <v-row>
                                <v-col cols="6">
                                    <v-select label="Template" v-model="pluginTemplate" :items="templateList"
                                        item-title="title" item-value="id" variant="outlined"
                                        :disabled="pluginName !== 'wis2box.data.csv2bufr.ObservationDataCSV2BUFR'"></v-select>
                                </v-col>
                                <v-col cols="6">
                                    <v-select label="WIS2 Buckets" v-model="pluginBuckets" :items="bucketList"
                                        item-title="title" item-value="id" multiple variant="outlined"></v-select>
                                </v-col>
                            </v-row>

                            <v-row>
                                <v-col cols="10">
                                    <v-text-field label="File Pattern (Regex)" v-model="pluginFilePattern"
                                        :hint="pluginPatternHint" variant="outlined"></v-text-field>
                                </v-col>
                                <v-col cols="2">
                                    <v-switch v-model="pluginNotifyBoolean" label="Notify
                                    " color="#003DA5"></v-switch>
                                </v-col>
                            </v-row>

                            <v-row>
                                <v-col cols="12">
                                    <v-btn color="#003DA5" variant="flat" block @click="savePlugin">Save</v-btn>
                                </v-col>
                            </v-row>
                        </v-col>
                    </v-container>
                </v-card>
            </v-dialog>

            <!-- Dialog for the user to view a link -->
            <v-dialog v-model="openViewLinkDialog" max-width="600px">
                <v-card>
                    <v-toolbar title="Link Viewer" color="#003DA5">
                        <v-btn icon="mdi-close" variant="text" size="small" @click="openViewLinkDialog = false" />
                    </v-toolbar>
                    <v-card-item>
                        <v-table class="my-2">
                            <tbody>
                                <tr>
                                    <td><b>Link URL</b></td>
                                    <td>{{ linkURL }}</td>
                                </tr>
                                <tr>
                                    <td><b>Link Description</b></td>
                                    <td>{{ linkTitle }}</td>
                                </tr>
                                <tr>
                                    <td><b>Link Type</b></td>
                                    <td>{{ linkType }}</td>
                                </tr>
                            </tbody>
                        </v-table>
                    </v-card-item>
                </v-card>
            </v-dialog>

            <!-- Dialog for the user to configure links -->
            <v-dialog v-model="openConfigureLinkDialog" max-width="750px">
                <v-card>
                    <v-toolbar title="Link Editor" color="#003DA5">
                        <v-btn icon="mdi-close" variant="text" size="small"
                            @click="openConfigureLinkDialog = false" />
                    </v-toolbar>
                    <v-container>
                        <v-col cols="12">
                            <v-row>
                                <v-col cols="12">
                                    <v-text-field label="Link URL" v-model="linkURL" :rules="[rules.url]" 
                                        hint="URL to the dataset or resource, has to be a valid URL (http/https)"
                                        variant="outlined">
                                    </v-text-field>
                                </v-col>
                            </v-row>
                            <v-row>
                                <v-col cols="12">
                                    <v-text-field label="Link Description" v-model="linkTitle" :rules="[rules.required]"
                                        hint="Descriptive title of the type and content of the link" variant="outlined">
                                    </v-text-field>
                                </v-col>
                            </v-row>
                            <v-row>
                                <v-col cols="12">
                                    <v-select label="Link Type" v-model="linkType" :items="linkTypeList" :rules="[rules.required]"
                                        item-title="description" item-value="rel" variant="outlined">
                                    </v-select>
                                </v-col>
                            </v-row>
                            <v-row>
                                <v-col cols="12">
                                    <v-btn color="#003DA5" variant="flat" block @click="saveLink">Save</v-btn>
                                </v-col>
                            </v-row>
                        </v-col>
                    </v-container>
                </v-card>
            </v-dialog>
        </v-col>
    </v-row>
</template>

<script>
import BboxEditor from "@/components/BboxEditor.vue";

import { defineComponent, ref, computed, onMounted, watch } from 'vue';
import { VCard, VForm, VBtn, VChipGroup, VChip, VCombobox } from 'vuetify/lib/components/index.mjs';
import Papa from 'papaparse';

const oapi = import.meta.env.VITE_API_URL;

export default defineComponent({
    name: "DatasetEditorForm",
    template: "#dataset-editor-form",
    props: ["topic"],
    components: {
        BboxEditor,
        VCard,
        VForm,
        VBtn,
        VChipGroup,
        VChip,
        VCombobox
    },
    setup() {

        const localID = ref('');
        const isEditing = computed(() => !isNew.value);

        const extractLocalID = (identifier) => {
            if (!identifier) {
                console.warn("Identifier is undefined or null");
                return ""; // Fallback empty string
            }
            const parts = identifier.split(":");
            return parts[parts.length - 1] || "";
        };

        const updateIdentifierFromLocalID = () => {
            const baseIdentifier = model.value.identification.identifier.split(":").slice(0, -1).join(":");
            model.value.identification.identifier = `${baseIdentifier}:${localID.value}`;
            if (items.value.includes(model.value.identification.identifier)) {
                message.value = "Identifier already exists. Please choose a different Local ID.";
                openMessageDialog.value = true;
                return;
            }
        };

        const random6ASCIICharacters = () => {
            let result = '';
            const characters = 'abcdefghijklmnopqrstuvwxyz0123456789';
            for (let i = 0; i < 6; i++) {
                result += characters.charAt(Math.floor(Math.random() * characters.length));
            }
            return result;
        };

        // Deep clone function to avoid reference issues between model and default model
        function deepClone(obj) {
            return JSON.parse(JSON.stringify(obj));
        }

        // Static variables

        // Default value of the form, not an exhaustive list of all fields
        const defaults = {
            identification: {
                identifier: 'urn:wmo:md:',
                keywords: [],
                links: [],
                wmoDataPolicy: 'core',
                isExperimental: false,
                subTopic1: 'weather',
                subTopic2: null,
                concepts: ['weather'],
                conceptScheme: 'https://codes.wmo.int/wis/topic-hierarchy/earth-system-discipline',
                licenseLink: null,
                isCustomLicense: true
            },
            extents: {
                // Default to the current date
                dateStarted: new Date().toISOString(),
                dateEnded: null
            },
            host: {},
            plugins: [],
            links: [],
            license_link: `${import.meta.env.VITE_BASE_URL}/data/license.txt`
        };

        // Time durations for resolution
        const durations = [
            { name: 'minutes(s)', code: 'TM' },
            { name: 'hour(s)', code: 'TH' },
            { name: 'day(s)', code: 'D' },
            { name: 'month(s)', code: 'M' },
            { name: 'year(s)', code: 'Y' }
        ];

        // link types for dataset links
        const linkTypeList = [
            { rel: 'archives', description: 'Online data archive' },
            { rel: 'service-desc', description: 'OpenAPI endpoint (such as JSON, YAML or OGC service capability)' }
        ];

        // WCMP2 schema version
        const schemaVersion = "http://wis.wmo.int/spec/wcmp/2/conf/core";

        // Validation patterns for form fields
        const rules = {
            required: value => !!value || "Field is required",
            dateRequired: value => (value !== null && value !== undefined) || "Date is required",
            identifier: value => !isNew.value || !items.value.includes(value) || "Identifier already exists",
            centreID: value => /^[a-z0-9_-]{2,}$/.test(value) || 'Invalid centre ID. Must be lowercase with at least 2 characters',
            latitude: value => value >= -90 && value <= 90 || 'Latitude must be between -90 and 90',
            longitude: value => value >= -180 && value <= 180 || 'Longitude must be between -180 and 180',
            url: value => value === '' || /^(https?:\/\/)((\d{1,3}\.){3}\d{1,3}|[-a-zA-Z0-9@:%._+~#=]{1,253}\.[a-z]{2,})(:\d{1,5})?(\/[-a-zA-Z0-9@:%_+.~#?&//=]*)?$/.test(value) || 'Invalid URL format',
            email: value => /^[a-z0-9._-]+@[a-z0-9-]+\.[a-z0-9.-]+$/.test(value) || 'Invalid email format',
            keywords: value => model.value.identification.keywords?.length >= 3 || 'There must be at least 3 keywords',
            token: value => !!value || 'Token is required'
        };

        // Define HTTP responses
        const OK = 200;
        const BAD_REQUEST = 400;
        const UNAUTHORIZED = 401;
        const FORBIDDEN = 403;
        const NOT_FOUND = 404;
        const CONFLICT = 409;
        const TOO_MANY_REQUESTS = 429;
        const INTERNAL_SERVER_ERROR = 500;

        // Reactive variables

        // Controls loading animation
        const working = ref(false);
        // Controls which parts of the page are displayed
        const metadataLoaded = ref(false);
        const formValidated = ref(false);
        const formFilled = ref(true);
        const formUpdated = ref(false);
        const formRef = ref(null);
        // If no datasets can be found and the user must create a new one, disable the dataset selection
        const datasetSpecified = ref(false);
        // Messages to display to user (this changes overtime)
        const message = ref("Select existing discovery metadata file or create a new file.");
        const submissionIssues = ref([]);
        // List of datasets to select from, if any
        const items = ref(['Loading...']);
        // Dialog for initial information when creating
        // a new dataset
        const showInitialDialog = ref(false);
        const centreList = ref([]);
        const templateFiles = ref([]);
        const selectedTemplate = ref(null);
        // Identifier of the selected dataset, used to load metadata from OAPI
        const identifier = ref("");
        // Dialog to confirm removal of dataset
        const openRemoveConfirmationDialog = ref(false);
        // List of languages and language codes
        const languageCodeList = ref([]);
        // List of country names, alph-2 codes, and alpha-3 codes
        const countryCodeList = ref([]);
        // List of earth system disciplines
        const earthSystemDisciplines = ref([]);
        // list of valid sub-topics
        const subTopics = ref([]);
        // list of valid sub-topics2
        const subTopics2 = ref([]);
        // list of valid license_options
        const license_options = ref([]);
        // Object of country alpha-2 codes with bounding boxes
        const boundingBoxes = ref({});
        // Whether or not the metadata is new or existing
        const isNew = ref(false);
        // Switch for whether end date is enabled
        const isEndDateDisabled = ref(true);
        const dateStartedError = ref('');
        const dateStoppedError = ref('');
        // Switch for whether Non-Real-Time dataset is selected
        const isNonRealTime = ref(false);
        // Geometry bounds
        const bounds = ref([[0, 0], [0, 0]]);
        // Country for the bbox - defaults to the host country
        const bboxCountry = ref(null);
        // Phone number validation for each field
        const isHostPhoneValid = ref(null);
        // Each keyword added by the user, before being added to the model
        const keyword = ref("");
        // Possible plugins and templates to select from
        const pluginList = ref([]);
        const templateList = ref([]);
        const bucketList = ref([]);
        // Information for creating/configuring a dataset plugin
        const pluginIsNew = ref(true);
        const pluginFileExtension = ref(null);
        const pluginName = ref(null);
        const pluginTemplate = ref(null);
        const pluginNotifyBoolean = ref(true);
        const pluginBuckets = ref(null);
        const pluginFilePattern = ref(null);
        const pluginPatternHint = ref("");
        // Information for plugin titles
        const pluginNameTitle = ref(null);
        const pluginTemplateTitle = ref(null);
        const pluginBucketsTitle = ref(null);
        // Information for storing the previous plugin name and filetype
        // when we overwrite the plugin info
        const previousPluginName = ref(null);
        const previousPluginFileExtension = ref(null);
        const previousPluginBuckets = ref(null);
        const previousPluginFilePattern = ref(null);
        // Information for creating/configuring a dataset link
        const linkIsNew = ref(true);
        const linkTitle = ref(null);
        const linkURL = ref(null);
        const linkType = ref(null);
        // Information for storing the previous link title and URL
        // when we overwrite the link info
        const previousLinkTitle = ref(null);
        const previousLinkURL = ref(null);
        const previousLinkRel = ref(null);
        // Metadata form to be filled
        const model = ref({ 'identification': {}, 'extents': {}, 'host': {}, 'plugins': [], 'links': [] , 'license_link': defaults.license_link });
        // Execution token to be entered by user
        const token = ref(null);
        // Variable to control whether token is seen or not
        const showToken = ref(false);
        // Help dialog windows
        const openInitialHelpDialog = ref(false);
        const openIdentificationHelpDialog = ref(false);
        const openTemporalHelpDialog = ref(false);
        const openSpatialHelpDialog = ref(false);
        const openHostHelpDialog = ref(false);
        const openDistribHelpDialog = ref(false);
        const openPluginHelpDialog = ref(false);
        const openLinkHelpDialog = ref(false);
        const openTokenHelpDialog = ref(false);

        // Message dialog windows
        const openMessageDialog = ref(false);

        const copyIdentifier = () => {
            const identifier = model.value?.identification?.identifier;

            if (!identifier) {
                console.warn("Identifier is undefined. Cannot copy to clipboard.");
                message.value = "No identifier to copy.";
                openMessageDialog.value = true;
                return;
            }

            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(identifier)
                    .then(() => {
                        message.value = "Identifier copied to clipboard!";
                        openMessageDialog.value = true;
                    })
                    .catch(err => {
                        console.error('Clipboard API error: ', err);
                        fallbackCopyManual(identifier);
                    });
            } else {
                fallbackCopyManual(identifier);
            }
        };

        const fallbackCopyManual = (text) => {
            if (text) {
                const textarea = document.createElement('textarea');
                textarea.value = text;
                document.body.appendChild(textarea);
                textarea.select();
                document.execCommand('copy');
                document.body.removeChild(textarea);

                message.value = "Text copied!";
                openMessageDialog.value = true;
            } else {
                message.value = "No text available to copy.";
                openMessageDialog.value = true;
            }
        };

        const openValidationDialog = ref(false);
        const openSuccessDialog = ref(false);

        // Plugin dialog windows
        const openViewPluginDialog = ref(false);
        const openConfigurePluginDialog = ref(false);
        
        const openViewLinkDialog = ref(false);
        const openConfigureLinkDialog = ref(false);

        // Computed variables

        // Is the dataset being updated, so can be removed?
        const datasetIsBeingUpdated = computed(() => {
            return items.value.includes(model.value.identification.identifier) && !isNew.value;
        })

        // transfer to lowercase in realtime
        const convertToLowercase = (value) => {
            model.value.identification.centreID = value.toLowerCase();
        };


        const convertToLowercaseLocalID = (value) => {
            if (!value) {
                localID.value = '';
                return;
            }
            localID.value = value
                .trim()
                .toLowerCase()
                .replace(/\s+/g, '-');
            };

        // Has the user filled the dialog window?
        const initialDialogFilled = computed(() => {
            return model.value.identification.centreID && (selectedTemplate.value || isNonRealTime.value);
        });

        // Filter the country code list so that only the countries
        // which have an automatic bounding box are shown
        const filteredCountryCodeList = computed(() => {
            const filteredList = countryCodeList.value.filter(country => {
                // Find out if the (lower case) alpha 2 code is in the bbox list
                return country["alpha-2"].toLowerCase() in boundingBoxes.value;
            });
            // Create a global option
            const global = { "name": "Global", "alpha-2": "int", "alpha-3": "int" };
            // Add this global option to the start of the list
            filteredList.unshift(global);
            return filteredList;
        });

        // If the end date is specified, is it after the start date
        // Note: The nested if statements are written this way to avoid this boolean ever being true
        // (this makes the datepicker component show a green border which is not desired)
        const endDatePossible = computed(() => {
            const dateStopped = new Date(model.value.extents?.dateStopped);
            const dateStarted = new Date(model.value.extents?.dateStarted);

            const dateStoppedWithoutTime = new Date(dateStopped.getFullYear(), dateStopped.getMonth(), dateStopped.getDate());
            const dateStartedWithoutTime = new Date(dateStarted.getFullYear(), dateStarted.getMonth(), dateStarted.getDate());

            if (dateStoppedWithoutTime < dateStartedWithoutTime) {
                return false;
            }
            return null;
        });

        // Controls whether the plugin table should be showed
        const canShowPluginTable = computed(() => {
            return metadataLoaded.value
        });
        

        // Methods

        // Fetches a list of metadata items from the OAPI and updates the list
        // This will be shown in the v-select component at the top of the page
        const loadList = async () => {
            try {
                // Get list of metadata items from wis2box
                const response = await fetch(`${oapi}/collections/discovery-metadata/items`)
                if (!response.ok) {
                    throw new Error('Network response was not okay, failed to load discovery metadata list.');
                }
                const responseData = await response.json();

                // Update the list of items
                items.value = responseData.features.map(item => item.properties.identifier);
                // Also get the centre IDs from this list
                const loadedCentres = responseData.features.map(item => item.wis2box["centre_id"]);
                centreList.value = [...new Set(loadedCentres)];
                // At this point, the user has not specified a dataset
                datasetSpecified.value = false;
            } catch (error) {
                console.error(error);
                // Display error message to the user
                message.value = 'Error loading discovery metadata list.';
                // Empty items
                items.value = []
            }
            // Now add the option to create a new dataset, regardless of whether
            // the list could be loaded or not
            items.value.push('Create New...');
        };

        // A method to help tidy the list of loaded centres IDs
        // to not include empty strings, global brokers, or duplications
        const tidyCentres = (list) => {
            let tidyList = list.filter(item => item);

            const globalBrokerSuffixes = [
                '-global-discovery-catalogue',
                '-global-broker',
                '-global-cache',
                '-global-monitor'
            ];

            tidyList = tidyList.filter(item => {
                return !globalBrokerSuffixes.some(suffix => item.endsWith(suffix));
            });

            tidyList = tidyList.filter(item => item);

            tidyList = tidyList.filter(centre => !centreList.value.includes(centre));

            return tidyList
        };

        // Fetches a list of centres from the metadata records


        // Fetches a list of official centres from the topic hierarchy repository
        // and updates the list
        const loadOfficialCentres = async () => {
            try {
                // Get list of official centres from raw GitHub link
                const response = await fetch("https://raw.githubusercontent.com/wmo-im/wis2-topic-hierarchy/main/topic-hierarchy/centre-id.csv");
                if (!response.ok) {
                    throw new Error('Network response was not okay, failed to load official centres list.');
                }
                // Get CSV response and parse it into an object
                const responseData = await response.text();
                const parsed = Papa.parse(responseData, { header: true });
                const list = parsed.data.map(item => item.Name);
                let officialCentres = tidyCentres(list);
                // Add these centres to the currently loaded list of centres
                // (Set a delay of 1 second to ensure the list is loaded first)
                setTimeout(() => {
                    centreList.value = centreList.value.concat(officialCentres);
                }, 1000);
            } catch (error) {
                console.error(error);
                // Display error message to the user
                message.value = 'Error loading official centres list.';
            }
        };

        // Fetches a list of earth system disciplines from the topic hierarchy
        // repository and updates the list
        const loadDisciplines = async () => {
            try {
                // Get earth system disciplines from raw GitHub link
                const response = await fetch("https://raw.githubusercontent.com/wmo-im/wis2-topic-hierarchy/main/topic-hierarchy/earth-system-discipline/index.csv");
                if (!response.ok) {
                    throw new Error('Network response was not okay, failed to load earth system disciplines.');
                }
                // Get CSV response and parse it into an object
                const responseData = await response.text();
                const parsed = Papa.parse(responseData, { header: true });
                // Filter out any empty data (the final row of the CSV)
                const filteredData = parsed.data.filter(item => item.Name && item.Description);
                // Map this data into the correct format for the v-select component
                earthSystemDisciplines.value = filteredData.map(item => ({
                    name: item.Name, description: item.Description
                }));
            } catch (error) {
                console.error(error);
                // Display error message to the user
                message.value = 'Error loading earth system disciplines list.';
            }
        };

        // Fetches a list of valid topics
        const loadTopics = async () => {
            try {
                // Get list of topics from the CSV file available within the current website
                const response = await fetch(`${window.location.origin}/wis2box-webapp/other/topics-dropdown-list.csv`);
                if (!response.ok) {
                    throw new Error('Network response was not okay, failed to load topics list.');
                }
                // Get CSV response and parse it into an object
                const responseData = await response.text();
                const parsed = Papa.parse(responseData, { header: true });
                // fill subTopics as an array of strings based on the first column in the csv
                // and filter out topics containing 'experimental'
                subTopics.value = parsed.data.map(item => item.Name).filter(item => !item.includes('experimental'));
            } catch (error) {
                console.error(error);
                // Display error message to the user
                message.value = 'Error loading topics list.';
            }
        };

        // Fetches a list of licences
        const loadLicenseOptions = async () => {
            try {
                // Get list of topics from the CSV file available within the current website
                const response = await fetch(`${window.location.origin}/wis2box-webapp/other/licenses-dropdown-list.csv`);
                if (!response.ok) {
                    throw new Error('Network response was not okay, failed to load topics list.');
                }
                // Get CSV response and parse it into an object
                const responseData = await response.text();
                const parsed = Papa.parse(responseData, { header: true });
                license_options.value = parsed.data.map(item => {
                    return {
                        label: `${item.link} (${item.description})`, 
                        value: item.link
                    };
                });
            } catch (error) {
                console.error(error);
                // Display error message to the user
                message.value = 'Error loading licenses list.';
            }
        };

        // Loads the data type templates
        const loadTemplates = async () => {
            // Load all JSON files in the templates folder
            const files = import.meta.glob('@/templates/*.json');

            // For each file, add the JSON data to the template list
            for (const path in files) {
                const file = await files[path]();
                templateFiles.value.push(file.default);
            }
            // Also push the 'other' datatype label
            templateFiles.value.push({ 'label': 'other' });
        };


        // When the user specifies a dataset identifier, load the corresponding metadata
        const loadMetadata = async () => {
            // Page values
            working.value = true;
            metadataLoaded.value = false;
            datasetSpecified.value = true;
            message.value = 'Loading discovery metadata...';

            // If the user selects 'Create New...', populate the form with default values
            if (identifier.value === "Create New...") {
                isNew.value = true;
                selectedTemplate.value = null;
                isEndDateDisabled.value = true;
                isNonRealTime.value = false; // Reset to default
                // Set model to default values
                model.value = deepClone(defaults);
                formValidated.value = false;
                // Open the dialog window
                showInitialDialog.value = true;
                // Reset identifier so that the user can reselect 'Create New...'
                // (the same value cannot be selected twice)
                identifier.value = "";
            }
            // Otherwise, populate the form with the loaded values
            else {
                isNew.value = false;
                try {
                    const response = await fetch(`${oapi}/collections/discovery-metadata/items/${identifier.value}`);
                    if (!response.ok) {
                        throw new Error('Network response was not okay, failed to load selected discovery metadata.');
                    }
                    const responseData = await response.json();
                    // The response data will have a different format to that of the form, so the data must be transformed
                    const formModel = transformToForm(responseData);
                    // Update the form (model) with the loaded values
                    model.value = formModel;
                    localID.value = extractLocalID(formModel.identification.identifier);
                    // Note: Set time delay to prevent watchers from firing too early
                    setTimeout(() => {
                        // Force bounding box map to update
                        updateBbox();
                        // As form was loaded, it must be already validated
                        formValidated.value = true;
                        // ...But it hasn't been updated yet
                        formUpdated.value = false;
                    }, 500); // Delay of 0.5 seconds
                } catch (error) {
                    console.log(error);
                    message.value = "Error loading selected discovery metadata file.";
                }
            }

            // Now update the UI

            // If no error, display the form and present a success message
            if (!message.value.includes("Error")) {
                metadataLoaded.value = true;
                message.value = "Dataset loaded successfully.";
            }
            // Remove working animation
            working.value = false;
        };

        // When the metadata is loaded, it must be transformed to the format of the form
        // (this is because the form has a different structure to the schema)
        // It is easier to understand the transformToSchema method first, because this
        // method is just the inverse of that one
        const transformToForm = (schema) => {
            // Initialize form model
            let formModel = {
                identification: {},
                extents: {},
                host: {},
                settings: {},
                links: [],
                license_link: defaults.license_link
            };

            // Plugins information
            if (schema.wis2box["data_mappings"]?.plugins) {
                formModel.plugins = tidyPlugins(schema.wis2box["data_mappings"].plugins);
                // if there are no plugins isNonRealTime should be true
                if (formModel.plugins.length === 0) {
                    console.log("No plugins found, setting isNonRealTime to true");
                    isNonRealTime.value = true;
                }
                else {
                    console.log("Plugins found, setting isNonRealTime to false");
                    isNonRealTime.value = false; // If there are plugins, it is a real-time dataset
                }
            }
            else {
                console.log("No plugins found, setting isNonRealTime to true");
                formModel.plugins = [];
                isNonRealTime.value = true; // No plugins means it is a non-real-time dataset
            }

            let license_link = null;
            // loop over links in the schema and when rel='license' set the licenseLink
            schema.links.forEach(link => {
                if (link.rel === 'license') {
                    license_link = link.href;
                } else if (link.rel === 'archives') {
                    formModel.links.push({
                        title: link.title,
                        href: link.href,
                        rel: link.rel
                    });
                } else if (link.rel === 'service-desc') {
                    formModel.links.push({
                        title: link.title,
                        href: link.href,
                        rel: link.rel
                    });
                }
            });
            // check if the link is license_options, if not it is a customLicense
            let is_custom_license = true;
            for (const option of license_options.value) {
                if (license_link === option.value) {
                    is_custom_license = false;
                    return;
                }
            }
            // Set the license link and whether it is a custom license
            formModel.identification.isCustomLicense = is_custom_license;
            formModel.identification.licenseLink = license_link;

            // Retrieve the identifier from the schema
            formModel.identification.identifier = schema.id;

            // Centre ID from wis2box section
            formModel.identification.centreID = schema.wis2box['centre_id'];

            // Topic hierarchy from properties section, removing
            // the 'origin/a/wis2' prefix
            if (schema.properties['wmo:topicHierarchy']) {
                let fullTopic = schema.properties['wmo:topicHierarchy'];
                console.log("wmo:topicHierarchy=", fullTopic);
                schema.properties['wmo:topicHierarchy'];
                formModel.identification.topicHierarchy = fullTopic.replace(/origin\/a\/wis2\//g, '');
                // subTopic1 is the 7th-level
                formModel.identification.subTopic1 = fullTopic.split('/')[6];
                // subTopic2 is the everything after the 7th level unless it starts with experimental
                if (fullTopic.split('/')[7] === 'experimental') {
                    formModel.identification.isExperimental = true;
                    // subTopic2 is everything after experimental
                    formModel.identification.subTopic2 = fullTopic.split('/').slice(8).join('/');
                    console.log("subTopic2 is experimental, set to: ", formModel.identification.subTopic2);
                }
                else {
                    formModel.identification.isExperimental = false;
                    formModel.identification.subTopic2 = fullTopic.split('/').slice(7).join('/');
                }
            }
            else  {
                formModel.identification.topicHierarchy = null;
            }
            
            // Time period information
            if (schema.time?.interval) {
                formModel.extents.dateStarted = schema.time.interval[0];
                formModel.extents.dateStopped = schema.time.interval[1];
            }

            // Disable 'Dataset ongoing' checkbox if the end date is specified
            if (schema.time?.interval[1] !== "..") {
                isEndDateDisabled.value = false;
            }

            // Minimum time period resolvable in the dataset
            if (schema.time?.resolution) {
                // match on Days, Months, or Years
                const match = schema.time.resolution.match(/P(\d+)([DMY])/i);
                if (match) {
                    formModel.extents.resolution = parseInt(match[1]);
                    formModel.extents.resolutionUnit = match[2].toUpperCase();
                }
                // match on Hours, Minutes
                const match2 = schema.time.resolution.match(/PT(\d+)([HM])/i);
                if (match2) {
                    formModel.extents.resolution = parseInt(match2[1]);
                    formModel.extents.resolutionUnit = `T${match2[2].toUpperCase()}`;
                }
                // print to console if no match found
                if (!match && !match2) {
                    console.warn("No match found for time resolution: ", schema.time.resolution);
                }
            }

            // Geometry information
            if (schema.geometry?.coordinates && schema.geometry?.coordinates[0].length >= 4) {
                const coordinates = schema.geometry.coordinates[0];
                formModel.extents.westLongitude = coordinates[0][0];
                formModel.extents.northLatitude = coordinates[0][1];
                formModel.extents.eastLongitude = coordinates[2][0];
                formModel.extents.southLatitude = coordinates[2][1];
            }

            // Properties information
            formModel.identification.title = schema.properties.title;
            formModel.identification.description = schema.properties.description;
            formModel.identification.language = {code: schema.properties.language};
            formModel.identification.keywords = schema.properties.keywords;

            // Themes - hardcoded for now
            formModel.identification.concepts = ["weather"];
            formModel.identification.conceptScheme = "https://codes.wmo.int/wis/topic-hierarchy/earth-system-discipline";

            // Contacts information
            const structureHostDetails = (contact) => {
                return {
                    individual: contact.name,
                    positionName: contact.position,
                    name: contact.organization,
                    phone: contact.phones ? contact.phones[0].value : '',
                    email: contact.emails ? contact.emails[0].value : '',
                    deliveryPoint: contact.addresses ? contact.addresses[0].deliveryPoint : '',
                    city: contact.addresses ? contact.addresses[0].city : '',
                    administrativeArea: contact.addresses ? contact.addresses[0].administrativeArea : '',
                    postalCode: contact.addresses ? contact.addresses[0].postalCode : '',
                    country: contact.addresses ? contact.addresses[0].country : '',
                    hoursOfService: contact.hoursOfService,
                    contactInstructions: contact.contactInstructions,
                    url: contact.links ? contact.links[0].href : ''
                };
            }
            schema.properties.contacts.forEach(contact => {
                if (contact.roles?.includes("host")) {
                    formModel.host = structureHostDetails(contact);
                }
            });

            // Additional settings information
            if (schema.properties["wmo:dataPolicy"]) {
                formModel.identification.wmoDataPolicy = schema.properties["wmo:dataPolicy"];
            }
            // fill in the created date
            if (schema.properties.created) {
                formModel.extents.dateCreated = schema.properties.created;
            }

            return formModel;
        }

        // Dialog window for auto-filling form
        const continueToForm = () => {
            // Close the dialog
            showInitialDialog.value = false;

            if (selectedTemplate.value === null) {
                defaultIdentification();
                // set topic hierarchy to null
                model.value.identification.topicHierarchy = null;
            }
            else {
                // Autofill the form based on the input datatype label
                if (selectedTemplate.value.label !== 'other') {
                    applyTemplate(selectedTemplate.value);
                }
                else {
                    defaultIdentification();
                }
            }
        }

        // Find the corresponding alpha-2 code to an alpha-3 code
        const getAlpha2Code = (alpha3Code) => {
            // Check if the alpha-3 code is 'int' first
            if (alpha3Code === 'int') {
                return 'int';
            }
            // If it isn't 'int', find the corresponding alpha-2 code
            const country = countryCodeList.value.find(item => item["alpha-3"] === alpha3Code);
            // Return the code in lower case as we need it in this
            // form for founding the corresponding bbox
            return country["alpha-2"].toLowerCase();
        }

        // Get an automatic bounding box using the country code
        const getAutoBbox = async (alpha3Code) => {
            try {
                // Use this to find the corresponding alpha-2 code
                const alpha2Code = getAlpha2Code(alpha3Code);

                // Use the alpha-2 code to get the corresponding bbox
                const boundingBox = boundingBoxes.value[alpha2Code]['bbox'];

                // Now populate the form with the bounding box values
                model.value.extents.northLatitude = boundingBox.maxy;
                model.value.extents.eastLongitude = boundingBox.maxx;
                model.value.extents.southLatitude = boundingBox.miny;
                model.value.extents.westLongitude = boundingBox.minx;

            } catch (error) {
                console.error(error);
                message.value = "Error loading automatic bounding box.";
            }
        }

        // Loads the plugin lists from a separate JSON file
        const loadPluginLists = async () => {
            try {
                // Get list of plugins from JSON file
                const response = await fetch(`${import.meta.env.VITE_BASE_URL}/plugins/plugin-list.json`);
                if (!response.ok) {
                    throw new Error('Network response was not okay, failed to load plugin list.');
                }
                const responseData = await response.json();
                // Update the list of items
                pluginList.value = responseData.plugins;
                bucketList.value = responseData.buckets;
            } catch (error) {
                console.error(error);
                // Display error message to the user
                message.value = 'Error loading plugin list.';
            }
        };

        const loadMappings = async () => {
            try {
                const response = await fetch(`${import.meta.env.VITE_API_URL}/processes/mappings-info/execution`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        inputs: {
                            plugin: 'wis2box.data.csv2bufr.ObservationDataCSV2BUFR'
                        }
                    })
                });
                if (!response.ok) {
                    throw new Error('Failed to load templates from API.');
                }
                const data = await response.json();
                templateList.value = data.templates;
            } catch (error) {
                console.error(error);
                message.value = 'Error loading templates from API.';
            }
        };

        // Method to flatten the plugins array so it is easier to work with
        const tidyPlugins = (plugins) => {

            let result = [];

            for (const [filetype, entries] of Object.entries(plugins)) {
                entries.forEach(entry => {
                    const singlePlugin = {
                        fileType: filetype,
                        name: entry.plugin,
                        template: entry.template || undefined,
                        notify: entry.notify || undefined,
                        // Bucket names should be without 'wis2box-' prefix
                        buckets: entry.buckets || undefined,
                        filePattern: entry['file-pattern']
                    };
                    result.push(singlePlugin);
                })
            }

            return result;
        };

        const updateTopicHierarchy = () => {
            let policy = model.value.identification.wmoDataPolicy;
            let centreID = model.value.identification.centreID;
            let subTopic1 = model.value.identification.subTopic1;
            let subTopic2 = model.value.identification.subTopic2;
            //if subTopic2 is not defined set to 'undefined'
            if (model.value.identification.subTopic2 == null || model.value.identification.subTopic2 == undefined) {
                subTopic2 = 'undefined';
            }
            // if isExperimental than pre-pend experimental/ to subTopic2
            // and lowercase and remove special characters from subTopic2
            if (model.value.identification.isExperimental) {
                subTopic2 = 'experimental/' + subTopic2.toLowerCase().replace(/[^a-z0-9/-]/g, '');
            }
            model.value.identification.topicHierarchy = `origin/a/wis2/${centreID}/data/${policy}/${subTopic1}/${subTopic2}`;
        };

        // Autofill form based on template
        const applyTemplate = (template) => {
            // Metadata Editor parts
            if (template.title){
                model.value.identification.title = template.title.replace('$CENTRE_ID', model.value.identification.centreID);
            }
            const randomCode = random6ASCIICharacters();
            model.value.identification.identifier = 'urn:wmo:md:' + model.value.identification.centreID + ':' + randomCode;
            localID.value = extractLocalID(model.value.identification.identifier);
            // Converts the theme structure into a list of the theme labels
            model.value.identification.concepts = template.themes.flatMap(theme => theme.concepts.map(concept => concept.label));
            model.value.identification.conceptScheme = template.themes.map(theme => theme.scheme)[0];
            model.value.identification.keywords = template.keywords;
            // Use centre ID and WMO data policy to create topic hierarchy
            if(template.topicHierarchy) {
                model.value.identification.topicHierarchy = template.topicHierarchy
                    .replace('$CENTRE_ID', model.value.identification.centreID)
                    .replace('$DATA_POLICY', model.value.identification.wmoDataPolicy)
                    .replace(/\..*$/, '');
            }
            model.value.identification.isExperimental = false;
            model.value.identification.topicHierarchy = template.topicHierarchy
                .replace('$CENTRE_ID', model.value.identification.centreID)
                .replace('$DATA_POLICY', model.value.identification.wmoDataPolicy)
                .replace(/\..*$/, '');
            model.value.identification.subTopic1 = model.value.identification.topicHierarchy.split('/')[6];
            model.value.identification.subTopic2 = model.value.identification.topicHierarchy.split('/').slice(7).join('/');
            // Get resolution and resolution unit from template
            const match = template.resolution.match(/P(\d+)([DMY])/i);
            if (match) {
                model.value.extents.resolution = parseInt(match[1]);
                model.value.extents.resolutionUnit = match[2].toUpperCase();
            }
            const match2 = template.resolution.match(/PT(\d+)([HM])/i);
            if (match2) {
                model.value.extents.resolution = parseInt(match2[1]);
                model.value.extents.resolutionUnit = `T${match2[2].toUpperCase()}`;
            }
            // print to console if no match found
            if( !match && !match2) {
                console.warn("No match found for time resolution: ", template.resolution);
            }

            // Data Mappings Editor parts
            model.value.plugins = tidyPlugins(template.wis2box['data_mappings']['plugins']);
        };

        // Load language/country codes from a JSON file
        const loadCodes = async () => {
            // Load language codes
            try {
                const response = await fetch(`${import.meta.env.VITE_BASE_URL}/codelists/iso-639-1-languages.json`);
                if (!response.ok) {
                    throw new Error('Failed to load language codes.');
                }
                const responseData = await response.json();
                languageCodeList.value = responseData;
            } catch (error) {
                console.error(error);
                message.value = "Error loading language codes.";
            }
            // Load country codes
            try {
                const response = await fetch(`${import.meta.env.VITE_BASE_URL}/codelists/iso-3366-1-countries.json`);
                if (!response.ok) {
                    throw new Error('Failed to load country codes.');
                }
                const responseData = await response.json();
                countryCodeList.value = responseData;
            } catch (error) {
                console.error(error);
                message.value = "Error loading country codes.";
            }
            // Load bounding boxes
            try {
                const response = await fetch(`${import.meta.env.VITE_BASE_URL}/codelists/country-bbox.json`);
                if (!response.ok) {
                    throw new Error('Failed to load bounding boxes.');
                }
                const responseData = await response.json();
                // Remove the countries header as it is redundant
                boundingBoxes.value = responseData['countries'];
            } catch (error) {
                console.error(error);
                message.value = "Error loading default bounding boxes.";
            }
        };

        // Create sensible defaults for the identifier and topic
        // hierarchy when the user selects the 'other' datatype
        const defaultIdentification = () => {
            const randomCode = random6ASCIICharacters();
            let policy = model.value.identification.wmoDataPolicy;
            let centreID = model.value.identification.centreID;
            model.value.identification.identifier = 'urn:wmo:md:' + centreID + ':' + randomCode;
            localID.value = extractLocalID(model.value.identification.identifier);
            
            model.value.identification.topicHierarchy = centreID + '/data/' + policy + '/';
        }

        // Update the rectangle in the map when the user changes the bounding box
        const updateBbox = () => {
            bounds.value = [
                model.value.extents.northLatitude || 90,
                model.value.extents.eastLongitude || -180,
                model.value.extents.southLatitude || -90,
                model.value.extents.westLongitude || 180
            ];
        };

        // Validates the phone numbers entered by the user
        const onHostPhoneValidate = (output) => {
            isHostPhoneValid.value = output.valid;
        };

        // Adds a keyword to the model
        const addKeyword = () => {
            if (keyword.value !== "") {
                // Add keyword to array
                model.value.identification.keywords.push(keyword.value);
                keyword.value = "";
            }
        };

        // Remove keyword from model when chip is clicked
        const removeKeyword = (keywordToRemove) => {
            const index = model.value.identification.keywords.indexOf(keywordToRemove);
            if (index > -1) {
                // Create a shallow copy first
                let updatedKeywords = [...model.value.identification.keywords];

                // Remove the item at the specified index
                updatedKeywords.splice(index, 1);

                // Reassign the model's keywords to the updated array
                model.value.identification.keywords = updatedKeywords;
            }
        };

        // Formats the plugin name to be human readable
        // in the table of plugins
        const getPluginTitle = (plugin) => {
            if (!plugin) {
                return;
            }
            const foundPlugin = pluginList.value.find(item => item.id === plugin.name);

            if (!foundPlugin) {
                console.error(`No plugin found with id ${plugin.name}`);
                return;
            }

            return foundPlugin.title;
        };

        // Populates plugin fields
        const populatePluginFields = (plugin) => {
            // If plugin exists, populate the fields
            if (plugin) {
                pluginIsNew.value = false;
                pluginFileExtension.value = plugin.fileType;
                pluginName.value = plugin.name;
                pluginTemplate.value = plugin.template;
                pluginNotifyBoolean.value = plugin.notify;
                pluginBuckets.value = plugin.buckets;
                pluginFilePattern.value = plugin.filePattern;

                // Also populate human readable plugin titles
                pluginNameTitle.value = pluginList.value.find(item => item.id === plugin.name).title;
                pluginTemplateTitle.value = templateList.value.find(item => item.id === plugin.template)?.title;
                let listOfBucketTitles = plugin.buckets.map(bucket => {
                    return bucketList.value.find(item => item.id === bucket).title;
                });
                pluginBucketsTitle.value = listOfBucketTitles.join(', ');

            }
            // If plugin is new (null), reset the fields
            else {
                pluginIsNew.value = true;
                pluginFileExtension.value = null;
                pluginName.value = null;
                pluginTemplate.value = null;
                pluginNotifyBoolean.value = true;
                pluginBuckets.value = null;
                pluginFilePattern.value = null;
            }
        }

        // Let's the user see the details of the plugin without editing
        const viewPlugin = (plugin) => {
            // Open the view dialog
            openViewPluginDialog.value = true;

            populatePluginFields(plugin);
        };

        // Allows the user to configure a new or existing plugin, by automatically populating the fields
        const configurePlugin = (plugin) => {
            // Open the dialog
            openConfigurePluginDialog.value = true;

            // Save the original plugin name and filetype
            previousPluginName.value = plugin?.name;
            previousPluginFileExtension.value = plugin?.fileType;
            previousPluginBuckets.value = plugin?.buckets;
            previousPluginFilePattern.value = plugin?.filePattern;

            populatePluginFields(plugin);
        };

        // If the user changes the plugin name, use sensible defaults
        const defaultPluginFields = (name) => {
            // Find the plugin in the list
            const plugin = pluginList.value.find(item => item.id === name);

            // If the plugin is found, populate the fields
            if (plugin) {
                pluginFileExtension.value = plugin.defaultFileExtension;
                pluginTemplate.value = plugin?.defaultTemplate;
                pluginBuckets.value = plugin?.defaultBuckets;
                pluginFilePattern.value = plugin.defaultFilePattern;
                pluginPatternHint.value = plugin.hint;
            }
        }

        // Adds or updates the plugin in the model
        const savePlugin = () => {
            // If the plugin is new, add it to the model
            if (pluginIsNew.value) {
                // Create a new plugin object
                const newPlugin = {
                    fileType: pluginFileExtension.value,
                    name: pluginName.value,
                    template: pluginTemplate.value,
                    notify: pluginNotifyBoolean.value,
                    buckets: pluginBuckets.value,
                    filePattern: pluginFilePattern.value
                };
                // Add the plugin to the model
                model.value.plugins.push(newPlugin);
            }
            // Otherwise, update the existing plugin
            else {
                // Find the index of the plugin in the model
                const index = model.value.plugins.findIndex(item =>
                    item.name === previousPluginName.value &&
                    item.fileType === previousPluginFileExtension.value &&
                    item.buckets === previousPluginBuckets.value &&
                    item.filePattern === previousPluginFilePattern.value);
                // Update the plugin in the model
                model.value.plugins[index] = {
                    fileType: pluginFileExtension.value,
                    name: pluginName.value,
                    template: pluginTemplate.value,
                    notify: pluginNotifyBoolean.value,
                    buckets: pluginBuckets.value,
                    filePattern: pluginFilePattern.value
                };
            }
            // Close the dialog
            openConfigurePluginDialog.value = false;
        };

        // Allows the user to remove a plugin from the model
        const removePlugin = (plugin) => {
            // Find the index of the plugin in the model
            const index = model.value.plugins.findIndex(item => item.fileType === plugin.fileType && item.name === plugin.name);

            if (index > -1) {
                // Create a shallow copy first
                let updatedPluginList = [...model.value.plugins];

                // Remove plugin
                updatedPluginList.splice(index, 1);

                // Reassign updated list to model
                model.value.plugins = updatedPluginList;
            }
        };

        // Populates link fields
        const populateLinkFields = (link) => {
            // If link exists, populate the fields
            if (link) {
                linkIsNew.value = false;
                linkTitle.value = link.title;
                linkURL.value = link.href;
                linkType.value = link.rel;
            }
            // If link is new (null), reset the fields
            else {
                linkIsNew.value = true;
                linkTitle.value = null;
                linkURL.value = null;
                linkType.value = null;
            }
        }

        // Let's the user see the details of the link without editing
            const viewLink = (link) => {
            // Open the view dialog
            openViewLinkDialog.value = true;

            populateLinkFields(link);
        };

        // Allows the user to configure a new or existing links, prepopulating previous values
        const configureLink = (link) => {
            // Open the dialog
            openConfigureLinkDialog.value = true;
            // Save the original plugin name and filetype
            previousLinkTitle.value = link?.title;
            previousLinkURL.value = link?.href;
            previousLinkRel.value = link?.rel;

            populateLinkFields(link);
        };

        // Adds or updates the link in the model
        const saveLink = () => {
            // check if the link starts with http:// or https://
            if (!linkURL.value.startsWith('http://') && !linkURL.value.startsWith('https://')) {
                // return an error message
                message.value = 'The URL must start with http:// or https://';
                openMessageDialog.value = true;
                return;
            }
            // if url contains a space, it is invalid
            if(linkURL.value.includes(' ')){
                message.value = 'Not a valid URL';
                openMessageDialog.value = true;
                return;
            }
            
            // If the link is new, add it to the model
            if (linkIsNew.value) {
                // Create a new link object
                const newLink = {
                    title: linkTitle.value,
                    href: linkURL.value,
                    rel: linkType.value
                };
                // Add the link to the model
                model.value.links.push(newLink);
            }
            else {
                // Find the index of the link in the model
                const index = model.value.links.findIndex(item =>
                    item.title === previousLinkTitle.value &&
                    item.href === previousLinkURL.value &&
                    item.rel === previousLinkRel.value);
                // Update the link in the model
                model.value.links[index] = {
                    title: linkTitle.value,
                    href: linkURL.value,
                    rel: linkType.value
                };
            }
            // Close the dialog
            openConfigureLinkDialog.value = false;
        }

        // Allows the user to remove a link from the model
        const removeLink= (link) => {
            // Find the index of the link in the model
            const index = model.value.links.findIndex(item => item.title === link.title && link.href === link.href);

            if (index > -1) {
                // Create a shallow copy first
                let updatedLinkList = [...model.value.links];

                // Remove link
                updatedLinkList.splice(index, 1);

                // Reassign updated list to model
                model.value.links = updatedLinkList;
            }
        };


        // Method to get the date from a datetime
        const getDateFrom = (datetime) => {
            let date = new Date(datetime);
            let year = date.getFullYear();
            // getMonth() returns 0-11, so we add 1
            // Both the month and day must be padded with a 0 if they are less than 10
            let month = String(date.getMonth() + 1).padStart(2, '0');
            let day = String(date.getDate()).padStart(2, '0');

            // Format the date as YYYY-MM-DD
            let dateString = `${year}-${month}-${day}`;
            return dateString;
        };

        // Method to get the corresponding title from a earth system discipline concept
        const getTitleOf = (concept) => {
            const match = earthSystemDisciplines.value.find(item => item.name === concept);
            return match ? match.description : null;
        };

        // Method to remove spaces from formatted phone number
        const removeSpacesFrom = (phone) => {
            return phone.replace(/\s/g, '');
        };

        // Helper method to handling the end date
        const handleEndDate = (endDate) => {
            // The end date defaults to ".." if the dataset is ongoing
            if (isEndDateDisabled.value) {
                return ".."
            }
            else if (endDate) {
                return getDateFrom(endDate);
            }
            return ".."
        };

        // Method to structure the plugins object correctly for the schema
        const untidyPluginsForSchema = (plugins) => {
            let result = { "plugins": {} };
            for (const plugin of plugins) {
                // Create a new object which has the plugin
                // info except filetype
                let pluginInfo = {
                    plugin: plugin.name,
                    template: plugin.template,
                    notify: plugin.notify,
                    buckets: plugin.buckets,
                    'file-pattern': plugin.filePattern
                };

                result.plugins[plugin.fileType] = [pluginInfo];
            }
            return result;
        };

        // Helper method to format the WIS2 topic hierarchy
        const formatWIS2TopicHierarchy = (topic) => {
            // Remove the 'origin/a/wis2/' prefix
            // Replace the '/' with '.' to match the schema
            return topic.replace(/origin\/a\/wis2\//g, '').replace(/\//g, '.');
        }

        // Transforms the form data to the WCMP2 schema format
        const transformToSchema = (form) => {
            // Initialise schema model
            let schemaModel = {};

            // Starting information
            schemaModel.id = form.identification.identifier;
            schemaModel.conformsTo = [schemaVersion];
            schemaModel.type = "Feature";

            // wis2box information
            // Note: This is an extension to the WCMP2 schema
            schemaModel.wis2box = {
                "data_mappings": {},
                "centre_id": form.identification.centreID,
                "topic_hierarchy": null
            };
            // topic_hierarchy and data_mappings are only added if the data is non-real-time
            if(isNonRealTime.value === false) {
                schemaModel.wis2box["topic_hierarchy"] = formatWIS2TopicHierarchy(form.identification.topicHierarchy);
                schemaModel.wis2box["data_mappings"] = untidyPluginsForSchema(form.plugins);
            }

            // Time period information
            schemaModel.time = {};
            // Get the start and end dates from the form (removing the time part of the string)
            const startDate = getDateFrom(form.extents.dateStarted);
            const endDate = handleEndDate(form.extents.dateStopped);

            schemaModel.time.interval = [startDate, endDate];
            if (form.extents.resolution && form.extents.resolutionUnit) {
                if (form.extents.resolutionUnit === "TH") {
                    schemaModel.time.resolution = `PT${form.extents.resolution}H`;
                }
                else if (form.extents.resolutionUnit === "TM") {
                    schemaModel.time.resolution = `PT${form.extents.resolution}M`;
                }
                else {
                    schemaModel.time.resolution = `P${form.extents.resolution}${form.extents.resolutionUnit}`;
                }
            }

            // Geometry information
            schemaModel.geometry = {
                type: "Polygon",
                coordinates: [
                    [
                        // Top left corner
                        [form.extents.westLongitude, form.extents.northLatitude],
                        // Top right corner
                        [form.extents.eastLongitude, form.extents.northLatitude],
                        // Bottom right corner
                        [form.extents.eastLongitude, form.extents.southLatitude],
                        // Bottom left corner
                        [form.extents.westLongitude, form.extents.southLatitude],
                        // Back top top left corner to close the polygon
                        [form.extents.westLongitude, form.extents.northLatitude]
                    ]
                ]
            };

            // Properties information
            schemaModel.properties = {};
            schemaModel.properties.type = "dataset";
            schemaModel.properties.identifier = form.identification.identifier;
            schemaModel.properties.title = form.identification.title;
            schemaModel.properties.description = form.identification.description;
            schemaModel.properties.language = {code: null};
            schemaModel.properties.keywords = form.identification.keywords;
            // Themes
            const concepts = form.identification.concepts.map(item => ({ id: item, title: getTitleOf(item) }));
            schemaModel.properties.themes = [
                {
                    concepts: concepts,
                    scheme: form.identification.conceptScheme
                }
            ]
            // Contacts information
            schemaModel.properties.contacts = [];
            // Point of contact
            const hostDetails = {
                name: form.host.individual,
                position: form.host.positionName,
                organization: form.host.name,
                emails: [{
                    value: form.host.email
                }],
                addresses: [{
                    deliveryPoint: form.host.deliveryPoint,
                    city: form.host.city,
                    administrativeArea: form.host.administrativeArea,
                    postalCode: form.host.postalCode,
                    country: form.host.country
                }],
                links: [{
                    rel: "about",
                    href: form.host.url,
                    type: "text/html"
                }],
                hoursOfService: form.host.hoursOfService,
                contactInstructions: form.host.contactInstructions,
                roles: ["host"]
            };

            // Add optional phone number if it exists
            if (form.host.phone) {
                hostDetails.phones = [];
                hostDetails.phones.push({ value: removeSpacesFrom(form.host.phone) });
            }

            schemaModel.properties.contacts.push(hostDetails);

            const currentDTNoMilliseconds = new Date().toISOString().slice(0, -5) + "Z";

            // If the metadata has been loaded, use the original creation date. Otherwise use today
            schemaModel.properties.created = form.extents.dateCreated || currentDTNoMilliseconds;
            schemaModel.properties.updated = currentDTNoMilliseconds;
            schemaModel.properties["wmo:dataPolicy"] = form.identification.wmoDataPolicy;

            // If the data is not non-real-time, add the topic hierarchy
            if (form.identification.topicHierarchy && isNonRealTime.value === false) {
                schemaModel.properties["wmo:topicHierarchy"] = `${form.identification.topicHierarchy}`;
            }
            schemaModel.properties.id = form.identification.identifier;
            schemaModel.links = [];
            // add add link in form.links to schemaModel.links
            if (form.links && form.links.length > 0) {
                form.links.forEach(link => {
                    schemaModel.links.push({
                        rel: link.rel,
                        href: link.href,
                        title: link.title
                    });
                });
            }

            // add user-provided licenseLink to to schemaModel.links if data-policy is 'recommended'
            if (form.identification.wmoDataPolicy === 'recommended') {     
                schemaModel.links.push({
                    rel: "license",
                    href: form.identification.licenseLink,
                    title: "License for this dataset",
                    type: "text/html"
                });
            }
            return schemaModel;
        };

        // Validates the metadata form
        const validateForm = async () => {
            const { valid } = await formRef.value.validate();

            // Check if date fields are filled
            dateStartedError.value = model.value.extents.dateStarted ? '' : 'Begin Date is required.';
            dateStoppedError.value = model.value.extents.dateStopped || isEndDateDisabled.value ? '' : 'End Date is required.';

            const isFormValid = valid && (!model.value.host.phone || isHostPhoneValid.value) &&
                (isNonRealTime.value === false || model.value.links.length !== 0) &&
                !dateStartedError.value && !dateStoppedError.value;

            message.value = isFormValid
                ? "Form is valid, please proceed."
                : "Form is invalid, please check all of the fields are filled correctly and try again.";

            // add a message if there are no links for non-real-time data
            if (isNonRealTime.value && model.value.links.length === 0) {
                message.value += " At least one data-access-link must be added for metadata without WIS2 data notifications. ";
            }
            // add a message for dateStarted and dateStopped errors
            if (dateStartedError.value !== '') {
                message.value += " " + dateStartedError.value;
            }
            if (dateStoppedError.value !== '') {
                message.value += " " + dateStoppedError.value;
            }
            formValidated.value = isFormValid;

            openValidationDialog.value = true;
        };

        const handleFormDefaults = (centreID, identifier, topicHierarchy) => {
            // Set the default values for the form
            model.value = deepClone(defaults);

            // Set the centre ID to the original value
            model.value.identification.centreID = centreID;

            // If dataset exists, set the identifier and topic hierarchy
            // to what they were before (as they are uneditable)
            if (!isNew.value) {
                model.value.identification.identifier = identifier;
                model.value.identification.topicHierarchy = topicHierarchy;
            }
            // Otherwise, treat the form as it were just loaded from the
            // 'Continue to Form' button in the initial dialog
            else {
                continueToForm();
            }
        };

        // Resets the form to the default state, clearing the associated validation
        const resetForm = () => {
            const centreID = model.value.identification.centreID;
            const identifier = model.value.identification.identifier;
            const topicHierarchy = model.value.identification.topicHierarchy;

            handleFormDefaults(centreID, identifier, topicHierarchy);

            // Remove red boxes from validation errors
            formRef.value.resetValidation();

            formValidated.value = false;
            formFilled.value = false;
            message.value = "Form reset successfully.";
        };

        // Generates a downloadable JSON file from the filled and validated form, which follows the WCMP2 schema
        const downloadMetadata = () => {
            // Transform the model to the WCMP2 schema formatted version
            const schemaModel = transformToSchema(model.value);
            // Encode as a JSON
            const content = encodeURI(JSON.stringify(schemaModel, null, 4))
            const element = document.createElement("a")
            // Download the file
            element.href = "data:attachment/text," + content
            element.target = "_blank"
            element.download = "discovery-metadata.json"
            element.click()
        };

        const resetMessage = (type) => {
            if (type === 'typical') {
                openMessageDialog.value = false;
            }
            else if (type === 'validation') {
                openValidationDialog.value = false;
            }
            // Add a delay to prevent the message from disappearing on screen
            setTimeout(() => {
                message.value = "";
            }, 500);
        };

        const handleSubmitIssues = (issue, action) => {
            const issueIndex = submissionIssues.value.indexOf(issue);
            const issueExists = issueIndex !== -1;

            if (action === 'add' && !issueExists) {
                submissionIssues.value.push(issue);
            } else if (action === 'remove' && issueExists) {
                submissionIssues.value.splice(issueIndex, 1);
            }
        };

        const verifyFormIsFilled = async () => {
            const identifierError = rules.identifier(model.value.identification.identifier);
            if (identifierError !== true) {
                message.value = identifierError;
                openMessageDialog.value = true;
                return;
            }
            const checks = [
                { condition: !formValidated.value, message: "The form must be validated" },
                { condition: !formUpdated.value, message: "You must update the existing data" },
                { 
                    condition: (model.value.plugins?.length === 0 && !isNonRealTime.value),
                    message: "At least one plugin must be added" },
                {
                    condition: (model.value.links?.length === 0 && isNonRealTime.value),
                    message: "At least one link must be added for non-real-time data"
                },
                { condition: !token.value, message: "You must provide a 'processes/wis2box' token" }
            ];

            // Clear existing issues
            submissionIssues.value = [];

            checks.forEach(check => {
                handleSubmitIssues(check.message, check.condition ? 'add' : 'remove');
            });

            if (submissionIssues.value.length > 0) {
                message.value = "In order to submit the data, the following must be done first:";
                openMessageDialog.value = true;
            } else {
                await submitMetadata();
            }
        };

        // Redirects the user when they successfully submit data
        const redirectUser = () => {
            window.location.href = "/wis2box-webapp/dataset_editor";
        };

        const handleProcessError = (status) => {
            switch (status) {
                case UNAUTHORIZED:
                    message.value = "Unauthorized, please provide a valid 'processes/wis2box' token.";
                    break;
                case NOT_FOUND:
                    message.value = `Error submitting data: API not found.`;
                    break;
                case INTERNAL_SERVER_ERROR:
                    message.value = `Error submitting data: Internal server error.`;
                    break;
                case BAD_REQUEST:
                    message.value = "Bad request. Please check your request and try again.";
                    break;
                case FORBIDDEN:
                    message.value = "Forbidden. You do not have permission to access this resource.";
                    break;
                case CONFLICT:
                    message.value = "Conflict. Your request conflicts with the current state of the server.";
                    break;
                case TOO_MANY_REQUESTS:
                    message.value = "Too many requests in a given time. Please try again later.";
                    break;
                default:
                    message.value = `API error. Please check the console for more information.`;
            }
            // Open a dialog window to show this message clearly
            openMessageDialog.value = true;
        }

        // Removes the dataset from the collection
        const removeDataset = async () => {
            // Add authentication token to the headers
            const headers = {
                'Content-Type': 'application/json',
                'authorization': 'Bearer ' + token.value
            };

            const inputs = { "inputs": { "metadata_id": model.value.identification.identifier } }

            try {
                // Send the data to the unpublish and delete the dataset
                const response = await fetch(`${oapi}/processes/wis2box-unpublish_dataset/execution`, {
                    method: 'POST',
                    headers: headers,
                    body: JSON.stringify(inputs)
                });

                // Check response from OAPI before proceeding
                if (!response.ok) {
                    handleProcessError(response.status);
                    return;
                }

                const responseData = await response.json();

                // If the response is OK and the data status
                // is success, display a success message
                if (response.status === OK && responseData.status === "success") {
                    message.value = "Dataset removed successfully.";
                }

                // Otherwise, there must be an application-level error in the API
                else {
                    message.value = responseData.status;
                }

                // Open the success window to show this message clearly
                openSuccessDialog.value = true;
            }
            catch (error) {
                console.error(error);
                message.value = "Error removing dataset, please check the console for details.";
                openMessageDialog.value = true;
            }
        };

        // Submits the metadata to the wis2box OAPI endpoint
        const submitMetadata = async () => {
            // Add authentication token to the headers
            const headers = {
                'Content-Type': 'application/json',
                'authorization': 'Bearer ' + token.value
            };
            // Convert the form data to an object adhering to the WCMP2 schema
            const schemaModel = transformToSchema(model.value);
            // Adjust the structure of the schema model to fit the new process
            const inputs = { "inputs": { "metadata": schemaModel } }

            try {
                // Send the data to the publish dataset process
                const response = await fetch(`${oapi}/processes/wis2box-publish_dataset/execution`, {
                    method: 'POST',
                    headers: headers,
                    body: JSON.stringify(inputs)
                });

                // Check response from OAPI before proceeding
                if (!response.ok) {
                    handleProcessError(response.status);
                    return;
                }

                const responseData = await response.json();

                // If the response is OK and the data status
                // is success, display a success message
                if (response.status === OK && responseData.status === "success") {
                    message.value = isNew.value ? "Dataset added successfully!" : "Dataset updated successfully!";
                }

                // Otherwise, there must be an application-level error in the API
                else {
                    message.value = responseData.status || "Error submitting data, please check the console for details.";
                }

                // Open the success window to show this message clearly
                openSuccessDialog.value = true;
            }
            catch (error) {
                console.log(error);
                message.value = "Error submitting data, please check the console for details.";
                openMessageDialog.value = true;
            }
        };

        // Mounted
        onMounted(() => {
            loadList();
            loadOfficialCentres();
            loadDisciplines();
            loadTopics();
            loadTemplates();
            loadPluginLists();
            loadMappings();
            loadCodes();
            loadLicenseOptions();
        });

        // Watched

        // Watch for changes in the isNonRealTime value, for new datasets
        watch(isNonRealTime, (newValue) => {
            console.log(`isNonRealTime changed to ${newValue}`);
            if (isNew.value) {
                console.log("resetting dateStarted and dateStopped");
                selectedTemplate.value = null;
                if (newValue) {
                    model.value.extents.dateStarted = null;
                    model.value.extents.dateStopped = null;
                    isEndDateDisabled.value = false;
                }
                else {
                    // If the data is real-time, set the dateStarted to today and disable the end date
                    model.value.extents.dateStarted = new Date().toISOString();
                    model.value.extents.dateStopped = null;
                    isEndDateDisabled.value = true;
                }   
            }
        });

        watch(() => model.value.identification.subTopic1, () => {    
            // If the user changes sub-topic1, update the options in sub-topic2
            if (isNew.value) {
                const selectedSubTopic1 = model.value.identification.subTopic1;
                // Filter the subTopics list to include only options starting with subTopic1,
                // and remove the "subTopic1/" prefix from the string
                subTopics2.value = subTopics.value
                .filter(subTopic => subTopic.startsWith(selectedSubTopic1 + '/'))
                .map(subTopic => subTopic.replace(selectedSubTopic1 + '/', ''));
                // check if subTopic2 is in the list of subTopics2
                const isSubTopic2InList = subTopics2.value.includes(model.value.identification.subTopic2);
                // If subTopic2 is not in the list, set it to null
                if (!isSubTopic2InList) {
                    // Set subTopic2 to null
                    model.value.identification.subTopic2 = null;
                }
            }
        });

        watch(() => model.value.identification.isExperimental, () => {
            // If the user changes the isExperimental value set subTopic2 to null
            if (isNew.value) {
                model.value.identification.subTopic2 = null;
                updateTopicHierarchy();
            }
        });

        watch(() => model.value.identification.isCustomLicense, (newValue, oldValue) => {
            // If the user changes the isCustomLicense, set the licenseLink to null
            if (isNew.value) {
                model.value.identification.licenseLink = null;
            }
        });

        // If the user changes the data policy, update the topic hierarchy accordingly
        watch(() => model.value.identification.wmoDataPolicy, () => {
            updateTopicHierarchy();
        });
        // if the user changes the sub topic 1, update the topic hierarchy accordingly
        watch(() => model.value.identification.subTopic1, () => {
             updateTopicHierarchy();
        });
        // if the user changes the sub topic 2, update the topic hierarchy accordingly
        watch(() => model.value.identification.subTopic2, () => {
            updateTopicHierarchy();
        });

        // For each plugin name, auto populate the plugin fields
        watch(() => pluginName.value, () => {
            if (pluginName.value && pluginIsNew.value) {
                defaultPluginFields(pluginName.value);
            }
        });

        // If the user selects a non-CSV plugin, the template section should be blank
        watch(() => pluginName.value, () => {
            if (pluginName.value !== "wis2box.data.csv2bufr.ObservationDataCSV2BUFR") {
                pluginTemplate.value = null;
            }
        });

        // Disable the submit button until a change is made to the form
        watch(() => deepClone(model.value), (oldVal, newVal) => {
            if (oldVal !== newVal) {
                formUpdated.value = true;
            }
        });

        // Also set the validation state to false if the formFilled value changes
        watch(() => formFilled.value, (oldVal, newVal) => {
            // Set formValidated.value to false whenever formFilled is changed
            if (oldVal !== newVal) {
                formValidated.value = false;
            }
        });

        // Update the map when the user changes the bounding box
        watch(() => deepClone(model.value.extents), () => {
            updateBbox();
        });

        return {
            defaults,
            earthSystemDisciplines,
            subTopics,
            subTopics2,
            license_options,
            durations,
            linkTypeList,
            pluginList,
            templateList,
            bucketList,
            schemaVersion,
            rules,
            working,
            metadataLoaded,
            canShowPluginTable,
            formValidated,
            formFilled,
            formUpdated,
            formRef,
            datasetSpecified,
            message,
            submissionIssues,
            items,
            showInitialDialog,
            centreList,
            templateFiles,
            datasetIsBeingUpdated,
            openRemoveConfirmationDialog,
            convertToLowercase,
            initialDialogFilled,
            filteredCountryCodeList,
            endDatePossible,
            selectedTemplate,
            identifier,
            languageCodeList,
            countryCodeList,
            isNew,
            isEndDateDisabled,
            isNonRealTime,
            bounds,
            bboxCountry,
            isHostPhoneValid,
            keyword,
            pluginIsNew,
            pluginFileExtension,
            pluginName,
            pluginTemplate,
            pluginNotifyBoolean,
            pluginBuckets,
            pluginFilePattern,
            pluginPatternHint,
            pluginNameTitle,
            pluginTemplateTitle,
            pluginBucketsTitle,
            previousPluginName,
            previousPluginFileExtension,
            linkIsNew,
            linkTitle,
            linkURL,
            linkType,
            previousLinkTitle,
            previousLinkURL,
            previousLinkRel,
            model,
            token,
            showToken,
            openInitialHelpDialog,
            openIdentificationHelpDialog,
            openTemporalHelpDialog,
            openSpatialHelpDialog,
            openHostHelpDialog,
            openDistribHelpDialog,
            openPluginHelpDialog,
            openLinkHelpDialog,
            openTokenHelpDialog,
            openMessageDialog,
            openValidationDialog,
            openSuccessDialog,
            openViewPluginDialog,
            openConfigurePluginDialog,
            openViewLinkDialog,
            openConfigureLinkDialog,
            loadList,
            loadMetadata,
            continueToForm,
            getAutoBbox,
            onHostPhoneValidate,
            addKeyword,
            removeKeyword,
            getPluginTitle,
            viewPlugin,
            configurePlugin,
            savePlugin,
            removePlugin,
            viewLink,
            configureLink,
            saveLink,
            removeLink,
            removeDataset,
            validateForm,
            resetForm,
            downloadMetadata,
            resetMessage,
            redirectUser,
            verifyFormIsFilled,
            submitMetadata,
            copyIdentifier,
            fallbackCopyManual,
            updateIdentifierFromLocalID,
            extractLocalID,
            localID,
            isEditing,
            convertToLowercaseLocalID
        }
    }
});

</script>
<style scoped>
.row-spacer {
    height: 1rem;
}

.coordinate-rows {
    height: 4rem;
}

.clickable-row {
    cursor: pointer;
}

.plugin-buttons {
    text-align: right;
    vertical-align: middle;
}
</style>
