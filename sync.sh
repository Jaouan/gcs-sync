#!/bin/bash

bucket=$1
configFile=$2

[[ "${MIRROR}" == "true" ]] && mirrorFlag=true || mirrorFlag=false
[[ "${DRY_RUN}" == "true" ]] && dryRunFlag=true || dryRunFlag=false

tmpDir=./.tmp


function clean () {
    rm -Rf ${tmpDir}
}

function smartUnarchive () {
    [[ "${1}" =~ ".tar.gz" ]] && tar -xf ${1} -C ${2} &>/dev/null
    [[ "${1}" =~ ".zip" ]]    && unzip ${1} -d ${2} &>/dev/null
}


# - Clean before sync.
clean

# - Read sync file.
while read -r dst src; do
    # - Check if object exists, if not fetch assets.
    if [[ ${mirrorFlag} == false ]] && [[ $(gsutil ls gs://${bucket}${dst} &>/dev/null; echo $?) == 0 ]]; then
        echo "🟢 gs://${bucket}${dst} already synced."
    else
        ${mirrorFlag} && echo "🟣 gs://${bucket}${dst} will be mirrored. Fetching assets..." ||
                         echo "🟠 gs://${bucket}${dst} not synced. Fetching assets..."

        # - If remote archive, download it.
        localDst=${tmpDir}${dst}
        mkdir -p ${localDst}
        if [[ "${src}" =~ "https:" ]]; then
            remoteFileName="${src##*/}"
            curl -L -o ${localDst}/__${remoteFileName} ${src} &>/dev/null
            src=${localDst}/__${remoteFileName}
        fi
        
        # - Unarchive.
        smartUnarchive ${src} ${localDst}
        
        # - Clean downloaded archive.
        rm -Rf ${localDst}/__${remoteFileName}
    fi
done < ${configFile}

# - If nothing to synchronize, exit
[[ ! -d "${tmpDir}" ]] && echo "✅ gs://${bucket} is up-to-date. Nothing to synchronize." && exit 0

# - Display assets to synchronize.
echo "🔎 Will synchronize :"
(cd ${tmpDir} ; find -f .) | sed -e "s/[^-][^\/]*\// |/g" -e "s/|\([^ ]\)/|-\1/"

# - Synchronize.
if ${dryRunFlag}; then
    echo "✅ gs://${bucket} synchronized. (dry-run)"
else
    ${mirrorFlag} && (gsutil -m rsync -d -r ${tmpDir} gs://${bucket} &>/dev/null) ||
                     (gsutil -m rsync -r ${tmpDir} gs://${bucket} &>/dev/null)
    echo "✅ gs://${bucket} synchronized."
fi

# - Clean after sync.
clean
