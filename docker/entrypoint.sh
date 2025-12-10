#!/bin/sh

# Exit on error except where explicitly disabled
set -e

if [ -z "$WIS2BOX_URL" ]; then
  echo "ERROR: WIS2BOX_URL is not set"
  exit 1
fi

# Set VITE_URL to the value of WIS2BOX_URL/oapi
VITE_API_URL="$WIS2BOX_URL/oapi"
export VITE_API_URL
echo "VITE_API_URL=${VITE_API_URL}"

# Set VITE_BASE_URL to the value of WIS2BOX_URL/wis2box-webapp
VITE_BASE_URL="$WIS2BOX_URL/wis2box-webapp"
export VITE_BASE_URL
echo "VITE_BASE_URL=${VITE_BASE_URL}"

# Set VITE_BASEMAP_URL to WIS2BOX_BASEMAP_URL if it is set
if [ -z "$WIS2BOX_BASEMAP_URL" ]; then
  echo "WIS2BOX_BASEMAP_URL is not set, using default"
  VITE_BASEMAP_URL="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
else
  VITE_BASEMAP_URL="$WIS2BOX_BASEMAP_URL"
fi
export VITE_BASEMAP_URL
echo "VITE_BASEMAP_URL=${VITE_BASEMAP_URL}"

# repeat for VITE_BASEMAP_ATTRIBUTION
if [ -z "$WIS2BOX_BASEMAP_ATTRIBUTION" ]; then
  echo "WIS2BOX_BASEMAP_ATTRIBUTION is not set, using default"
  VITE_BASEMAP_ATTRIBUTION="<a href=\"https://osm.org/copyright\">OpenStreetMap</a> contributors"
else
  VITE_BASEMAP_ATTRIBUTION="$WIS2BOX_BASEMAP_ATTRIBUTION"
fi
export VITE_BASEMAP_ATTRIBUTION
echo "VITE_BASEMAP_ATTRIBUTION=${VITE_BASEMAP_ATTRIBUTION}"

# Homepage welcome message
if [ -z "$WIS2BOX_WEBAPP_HOMEPAGE_MESSAGE" ]; then
  echo "WIS2BOX_WEBAPP_HOMEPAGE_MESSAGE is not set, using default"
  VITE_WEBAPP_HOMEPAGE_MESSAGE="<h2>Welcome to the wis2box-webapp!</h2><br> This web-application allows you to configure your datasets, configure station metadata, submit FM-12/CSV data and monitor your WIS2-notifications."
else
  VITE_WEBAPP_HOMEPAGE_MESSAGE="$WIS2BOX_WEBAPP_HOMEPAGE_MESSAGE"
fi
export VITE_WEBAPP_HOMEPAGE_MESSAGE

set +e
sh docker/generate-topic-list.sh /wis2box-webapp/public/other
if [ $? -ne 0 ]; then
  echo "Topic list generation failed, continuing..."
fi
set -e

npm run build
npm run preview
