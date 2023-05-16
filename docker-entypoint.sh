#!/bin/bash

checkAndPrintVariable() {
  varName=$1
  varValue=${!varName}
  [[ -z "$varValue" ]] && { echo "$varName is empty, exiting..." ; exit 1; }
  echo "$varName: $varValue"
}

BUILD_DATE=$(date '+%m/%d/%Y')
printf "\nChecking env variables:\n"
checkAndPrintVariable "HASH_SDKJS"
checkAndPrintVariable "HASH_WEB_APPS"
checkAndPrintVariable "HASH_SERVER"
checkAndPrintVariable "BUILD_VERSION"
checkAndPrintVariable "BUILD_NUMBER"
checkAndPrintVariable "BUILD_DATE"
checkAndPrintVariable "CONNECTIONS"

printf "\nSetting PRODUCT_VERSION env equal to BUILD_VERSION = $BUILD_VERSION\n"
export PRODUCT_VERSION=$BUILD_VERSION

printf "\n\n\n################################\n"
printf "Building server..."
printf "\n################################\n"

printf "\nCloning repo...\n"
git clone https://github.com/ONLYOFFICE/server.git oo-server
cd oo-server || exit 1
git checkout "$HASH_SERVER"

printf "\nBuilding...\n"
npm ci || exit 1
npm install pkg | exit 1
./node_modules/.bin/grunt || exit 1

printf "\nSetting server parameters...\n"
cd build/server || exit 1
sed -i -E "s/(LICENSE_CONNECTIONS = )[[:digit:]]+/\1$CONNECTIONS/" Common/sources/constants.js
cat Common/sources/constants.js | grep LICENSE_CONNECTIONS
sed -i -E "s/(const buildNumber = )[[:digit:]]+/\1$BUILD_NUMBER/" Common/sources/commondefines.js
cat Common/sources/commondefines.js | grep "const buildNumber"
sed -i -E "s/(const buildVersion = )'[[:digit:].]+'/\1'$BUILD_VERSION'/" Common/sources/commondefines.js
cat Common/sources/commondefines.js | grep "const buildVersion"
sed -i -E "s_(const buildDate = )'[[:digit:]/]+'_\1'$BUILD_DATE'_" Common/sources/license.js
cat Common/sources/license.js | grep "const buildDate"

printf "\nPackaging server...\n"
cd DocService || exit 1
../../../node_modules/.bin/pkg . -t node14-linux --options max_old_space_size=4096 -o docservice

cp docservice /out/docservice
cd ../../../..

printf "\n\n\n################################\n"
printf "Cloning sdkjs..."
printf "\n################################\n\n"

git clone https://github.com/ONLYOFFICE/sdkjs.git sdkjs
cd sdkjs || exit 1
git checkout "$HASH_SDKJS"
cd ..

printf "\n\n\n################################\n"
printf "Building web-apps..."
printf "\n################################\n"

printf "\nCloning repo...\n"
git clone https://github.com/ONLYOFFICE/web-apps.git oo-web-apps
cd oo-web-apps || exit 1
git checkout "$HASH_WEB_APPS"

printf "\nSetting mobile editors parameters...\n"
sed -i "s/EditorUIController.isSupportEditFeature = () => false;/EditorUIController.isSupportEditFeature = () => true;/" apps/spreadsheeteditor/mobile/src/lib/patch.jsx
sed -i "s/EditorUIController.isSupportEditFeature = () => false;/EditorUIController.isSupportEditFeature = () => true;/" apps/presentationeditor/mobile/src/lib/patch.jsx
sed -i "s/return false/return true/" apps/documenteditor/mobile/src/lib/patch.jsx

printf "\nBuilding...\n"
cd build || exit 1
npx browserslist@latest --update-db
npm install -g grunt-cli
npm install
grunt --force

cd /out
mkdir documenteditor
mkdir presentationeditor
mkdir spreadsheeteditor

cp -r /oo-web-apps/deploy/web-apps/apps/documenteditor/mobile/dist/js/app.js /out/documenteditor/
cp -r /oo-web-apps/deploy/web-apps/apps/presentationeditor/mobile/dist/js/app.js /out/presentationeditor/
cp -r /oo-web-apps/deploy/web-apps/apps/spreadsheeteditor/mobile/dist/js/app.js /out/spreadsheeteditor/

printf "\n\n\nDone, docservice may be found at /out/docservice; mobile apps at /out/documenteditor, /out/presentationeditor, /out/spreadsheeteditor.\n"