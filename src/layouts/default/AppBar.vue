<template>
  <v-app-bar image="@/assets/banner.png">
    <img src="@/assets/logo-large.png" alt="Logo" class="wmo-logo" />

    <template v-slot:image>
      <!-- Gradient from white to transparent, ensuring at all sizes the blue logo
      will be on a solid background as required by the WMO -->
      <v-img gradient="to left, transparent, #FFFFFF"></v-img>
    </template>

    <v-app-bar-title class="wis2-title"> WIS2 in a box
    </v-app-bar-title>

  </v-app-bar>

  <v-navigation-drawer location="left" :width="200" rail expand-on-hover permanent="">

    <v-list :opened="open" dense nav>
      <v-list-item prepend-icon="mdi-home" title="Home" exact to="/" />

      <v-list-item prepend-icon="mdi-card-text" title="SYNOP Form" exact to="/synop2bufr" />

      <v-list-item prepend-icon="mdi-file-document" title="Dataset Editor" exact to="/dataset_editor" />

      <v-list-item prepend-icon="mdi-satellite-uplink" title="Stations" exact to="/station" />

      <v-list-item prepend-icon="mdi-chart-box" title="Monitoring" exact to="/monitoring" />
    </v-list>
  </v-navigation-drawer>
</template>

<script setup>

import { ref } from 'vue';

const open = ref(["Forms"])

</script>

<style scoped>
.bar-sizing {
  padding: 5px;
}

.wmo-logo {
  height: 60px;
  margin-left: 10px;
}

.wis2-title {
  color: #003DA5;
  font-size: 2rem;
  font-weight: 300;
}

.left-chevron {
  justify-content: center;
}

.right-chevron {
  justify-content: flex-end;
  padding-right: 5px;
}
</style>
