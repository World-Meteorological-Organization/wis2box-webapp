// Plugins
import vue from '@vitejs/plugin-vue'
import vuetify, { transformAssetUrls } from 'vite-plugin-vuetify'

// Utilities
import { defineConfig } from 'vite'
import { fileURLToPath, URL } from 'node:url'

// https://vitejs.dev/config/
export default defineConfig({
  base: '/wis2box-webapp/',
  plugins: [
    vue({ 
      template: { transformAssetUrls }
    }),
    // https://github.com/vuetifyjs/vuetify-loader/tree/next/packages/vite-plugin
    vuetify({
      autoImport: true,
      styles: {
        configFile: 'src/styles/settings.scss',
      },
    }),
  ],
  define: { 'process.env': {} },
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    },
    extensions: [
      '.js',
      '.json',
      '.jsx',
      '.mjs',
      '.ts',
      '.tsx',
      '.vue',
    ],
  },
  server: {
    host: '0.0.0.0',  // Required for Docker
    port: 3000,
  },
  preview: {
    host: '0.0.0.0',  // Required for Docker
    port: 4173,
  },
  build: {
    chunkSizeWarningLimit: 500,
    rollupOptions: {
      output: {
        manualChunks(id) {
          // External libraries
          if (id.includes('node_modules')) {
            if (id.includes('maplibre-gl')) return 'maplibre';
            if (id.includes('vuetify')) return 'vuetify';
            if (id.includes('date-fns')) return 'date-fns';
            if (id.includes('@fortawesome')) return 'fontawesome';
            if (id.includes('jsts')) return 'jsts';
            if (id.includes('libphonenumber-js')) return 'phone-utils';
            if (id.includes('@turf')) return 'turf';
            if (id.includes('leaflet')) return 'leaflet';
            if (id.includes('apexcharts')) return 'charts';
            if (id.includes('lodash')) return 'lodash';
            if (id.includes('@mdi')) return 'mdi-icons';
            if (id.includes('roboto-fontface')) return 'roboto';
            return 'vendor';
          }

          // Large app modules/components by path keyword
          if (id.includes('MonitoringPage')) return 'monitoring';
          if (id.includes('DatasetEditorForm')) return 'dataset-editor';
          if (id.includes('StationEditor')) return 'station-editor';

          return undefined;
        },
      },
    },
  },
})
