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

export name="${ROM} for ${device}"

if [ -e "${finalzip_path}" ]; then
    echo "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"

    echo "Uploading"

    export description="${ROM} for ${device} , Date: $(env TZ="${timezone}" date)" "${finalzip_path}"
    # Create a release
    release=$(curl -XPOST -H "Authorization:token ${GITHUB_TOKEN}" --data "{\"tag_name\": \"$tag\", \"target_commitish\": \"master\", \"name\": \"$name\", \"body\": \"$description\", \"draft\": false, \"prerelease\": false}" https://api.github.com/repos/${release_repo}/releases)
    # Extract the id of the release from the creation response
    id=$(echo "$release" | sed -n -e 's/"id":\ \([0-9]\+\),/\1/p' | head -n 1 | sed 's/[[:blank:]]//g')
    # Upload the artifact
    curl -XPOST -H "Authorization:token ${GITHUB_TOKEN}" -H "Content-Type:application/octet-stream" --data-binary @${finalzip_path} https://uploads.github.com/repos/${release_repo}/releases/$id/assets?name=${zip_name}
   
    echo "Uploaded"
else
    echo "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
    telegram -N -M "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
    exit 1
fi

if ["${ROM}" == "Sakura"]; then
   cd "${ROM_DIR}" && bash "vendor/lineage/build/tools/createjson.sh"
fi

if [ "${post_build_cleanup}" == "full" ]; then
    rm -rf out
elif [ "${post_build_cleanup}" == "device" ]; then
    rm -rf "${outdir}"
fi