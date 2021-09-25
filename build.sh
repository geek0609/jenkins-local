#!/bin/bash

export outdir="${ROM_DIR}/out/target/product/${device}"
BUILD_START=$(date +"%s")
echo "Build started for ${device}"
source build/envsetup.sh
source "${my_dir}/config.sh"
if [ -z "${buildtype}" ]; then
    export buildtype="userdebug"
fi
if [ "${ccache}" == "true" ] && [ -n "${ccache_size}" ]; then
    export USE_CCACHE=1
    ccache -M "${ccache_size}G"
elif [ "${ccache}" == "true" ] && [ -z "${ccache_size}" ]; then
    echo "Please set the ccache_size variable in your config."
    exit 1
fi
lunch "${rom_vendor_name}_${device}-${buildtype}"
if [ "${clean}" == "clean" ]; then
    mka clean
    mka clobber
elif [ "${clean}" == "installclean" ]; then
    mka installclean
elif [ "${clean}" == "remove_device_out" ]; then
    rm -rf "${outdir}"
else
    rm "${outdir}"/*$(date +%Y)*.zip*
fi
mka "${bacon}"
BUILD_END=$(date +"%s")
BUILD_DIFF=$((BUILD_END - BUILD_START))

export finalzip_path=$(ls "${outdir}"/*$(date +%Y)*.zip | tail -n -1)

export zip_name=$(echo "${finalzip_path}" | sed "s|${outdir}/||")
export tag=$( echo "$(date +%H%M)-${zip_name}" | sed 's|.zip||')

if [ -e "${finalzip_path}" ]; then
    echo "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"

    echo "Uploading"

    github-release "${release_repo}" "${tag}" "master" "${ROM} for ${device}

Date: $(env TZ="${timezone}" date)" "${finalzip_path}"
   
    echo "Uploaded"
else
    echo "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
    telegram -N -M "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
    exit 1
fi

if [${SAKURA_OFFICIAL}]; then
   bash vendor/lineage/build/tools/createjson.sh
fi