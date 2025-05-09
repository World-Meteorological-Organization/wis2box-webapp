#!/bin/bash

# check WIS2BOX_URL is set
if [ -z "$WIS2BOX_URL" ]; then
  echo "WIS2BOX_URL is not set"
  exit 1
fi

# Set VITE_URL to the value of WIS2BOX_URL/oapi
echo "VITE_API_URL=$WIS2BOX_URL/oapi"
export VITE_API_URL=$WIS2BOX_URL/oapi

# Set VITE_BASE_URL to the value of WIS2BOX_URL/wis2box-webapp
echo "VITE_BASE_URL=$WIS2BOX_URL/wis2box-webapp"
export VITE_BASE_URL=$WIS2BOX_URL/wis2box-webapp

# Set VITE_BASEMAP_URL to WIS2BOX_BASEMAP_URL if it is set
if [ -z "$WIS2BOX_BASEMAP_URL" ]; then
  echo "WIS2BOX_BASEMAP_URL is not set use default basemap"
  VITE_BASEMAP_URL="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
else
  export VITE_BASEMAP_URL=$WIS2BOX_BASEMAP_URL
fi
echo "VITE_BASEMAP_URL=$VITE_BASEMAP_URL"

# repeat for VITE_BASEMAP_ATTRIBUTION
if [ -z "$WIS2BOX_BASEMAP_ATTRIBUTION" ]; then
  echo "WIS2BOX_BASEMAP_ATTRIBUTION is not set use default basemap attribution"
  VITE_BASEMAP_ATTRIBUTION="<a href="https://osm.org/copyright">OpenStreetMap</a> contributors"
else
  export VITE_BASEMAP_ATTRIBUTION=$WIS2BOX_BASEMAP_ATTRIBUTION
fi
echo "VITE_BASEMAP_ATTRIBUTION=$VITE_BASEMAP_ATTRIBUTION"

# vite welcome message
if [ -z "$WIS2BOX_WEBAPP_HOMEPAGE_MESSAGE" ]; then
  echo "WIS2BOX_WEBAPP_HOMEPAGE_MESSAGE is not set use default"
  VITE_WEBAPP_HOMEPAGE_MESSAGE="<h2>Welcome to the wis2box-webapp!</h2><br> This web-application allows you to configure your datasets, configure station metadata, submit FM-12/CSV data and monitor your WIS2-notifications.  "
else
  export VITE_WEBAPP_HOMEPAGE_MESSAGE=$WIS2BOX_WEBAPP_HOMEPAGE_MESSAGE
fi

set +e
# run generate-topic-list.sh
docker/generate-topic-list.sh /wis2box-webapp/public/wth || echo "Topic list generation failed, continuing..."
set -e

npm run build
npm run preview
