#!/bin/bash

checkAndPrintVariable() {
  varName=$1
  varValue=${!varName}
  [[ -z "$varValue" ]] && { echo "$varName is empty, exiting..." ; exit 1; }
  echo "$varName: $varValue"
}

BUILD_DATE=$(date '+%m/%d/%Y')
printf "\nChecking env variables:\n"
checkAndPrintVariable "HASH"
checkAndPrintVariable "BUILD_VERSION"
checkAndPrintVariable "BUILD_NUMBER"
checkAndPrintVariable "BUILD_DATE"
checkAndPrintVariable "CONNECTIONS"

printf "\nCloning repo...\n"
git clone https://github.com/ONLYOFFICE/server.git oo-server
cd oo-server || exit 1
git checkout "$HASH"

printf "\nBuilding...\n"
npm ci || exit 1
npm install pkg | exit 1
./node_modules/.bin/grunt || exit 1

printf "\nSetting parameters...\n"
cd build/server || exit 1
sed -i -E "s/(LICENSE_CONNECTIONS = )[[:digit:]]+/\1$CONNECTIONS/" Common/sources/constants.js
cat Common/sources/constants.js | grep LICENSE_CONNECTIONS
sed -i -E "s/(const buildNumber = )[[:digit:]]+/\1$BUILD_NUMBER/" Common/sources/commondefines.js
cat Common/sources/commondefines.js | grep "const buildNumber"
sed -i -E "s/(const buildVersion = )'[[:digit:].]+'/\1'$BUILD_VERSION'/" Common/sources/commondefines.js
cat Common/sources/commondefines.js | grep "const buildVersion"
sed -i -E "s_(const buildDate = )'[[:digit:]/]+'_\1'$BUILD_DATE'_" Common/sources/license.js
cat Common/sources/license.js | grep "const buildDate"

printf "\nPackaging...\n"
cd DocService || exit 1
../../../node_modules/.bin/pkg . -t node14-linux --options max_old_space_size=4096 -o docservice

cp docservice /out/docservice

printf "\nDone, docservice may be found at /out/docservice.\n"