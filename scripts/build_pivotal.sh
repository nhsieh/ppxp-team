#!/bin/bash

set -e

P_RUNTIME_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
P_RUNTIME_METADATA=${P_RUNTIME_DIR}/metadata/cf.yml

echo "------------- metadata_parts/binaries.yml -------------"
cat ${P_RUNTIME_DIR}/metadata_parts/binaries.yml
echo "------------- metadata_parts/binaries.yml -------------"

rm -f ${P_RUNTIME_DIR}/*.pivotal
rm -f ${P_RUNTIME_DIR}/*.pivotal.yml

bundle install
bundle exec vara-build-metadata --product-dir="${P_RUNTIME_DIR}"
bundle exec vara-download-artifacts --product-metadata="${P_RUNTIME_METADATA}"
bundle exec vara-build-pivotal      --product-metadata="${P_RUNTIME_METADATA}" --rc="-build${BUILD_NUMBER:--local}"
