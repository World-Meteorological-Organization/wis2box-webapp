// Composables
import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    children: [
      {
        path: '',
        name: 'Home',
        component: () => import('@/views/Home.vue'),
      },
      {
        path: 'manual_upload',
        name: 'ManualUploadForm',
        component: () => import('@/views/ManualUploadForm.vue'),
        meta: {title: 'wis2box - Manual Data File Upload'}
      },
      {
        path: 'synop2bufr',
        name: 'SynopForm',
        component: () => import('@/views/SynopForm.vue'),
        meta: {title: 'wis2box - Synop Form'}
      },
      {
        path: 'monitoring', // New route for the notifications page
        name: 'Monitoring',
        component: () => import('@/views/MonitoringPage.vue'),
        meta: {title: 'wis2box - Monitoring'}
      },
      {
        path: 'dataset_editor',
        name: 'DatasetEditorForm',
        component: () => import('@/views/DatasetEditorForm.vue'),
        meta: {title: 'wis2box - Dataset Editor Form'}
      },
      {
        path: '/import-station',
        name: 'importOSCAR',
        component: () => import('@/views/ImportOSCAR.vue'),
        meta: {title: 'Import from OSCAR'}
      },
      {
        path: '/station',
        name: 'stationTable',
        component: () => import('@/views/StationTable.vue'),
        meta: {title: 'View stations'}
      },
      {
        path: '/station/:id(.*)',
        children: [
          {
            path: '',
            name: 'stationEditor',
            component: () => import('@/views/StationEditor.vue'),
            meta: {title: 'Create / register new station'}
          }
        ]
      }
    ],
  },
]

// Create the router
const router = createRouter({
  history: createWebHistory('/wis2box-webapp/'),
  routes,
})

// Assign the title of the browser tab for each page
router.beforeEach((to, from, next) => {
  const nearestWithTitle = to.matched.slice().reverse().find(r => r.meta && r.meta.title);
  if(nearestWithTitle) document.title = nearestWithTitle.meta.title;
  next();
});

export default router
