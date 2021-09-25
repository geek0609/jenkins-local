#!/bin/bash
echo "Sync started for ${manifest_url}/tree/${branch}"
SYNC_START=$(date +"%s")
if [ ! -d "${ROM_DIR}"/.repo ]; then
    repo init -u "${manifest_url}" -b "${branch}" --depth 1
fi
rm -rf .repo/local_manifests
mkdir -p .repo/local_manifests
wget "${local_manifest_url}" -O .repo/local_manifests/manifest.xml
repo sync --current-branch --force-sync --no-clone-bundle --no-tags --optimized-fetch --prune 
syncsuccessful="${?}"
SYNC_END=$(date +"%s")
SYNC_DIFF=$((SYNC_END - SYNC_START))
if [ "${syncsuccessful}" == "0" ]; then
    echo "Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
    source "${my_dir}/build.sh"
else
    echo "Sync failed in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
    exit 1
fi
