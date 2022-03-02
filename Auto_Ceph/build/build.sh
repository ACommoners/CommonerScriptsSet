#!/bin/bash

function usage {
    cat <<EOF
Usage: sh build.sh [options]

Options:
    --tag, -t <image_tag>              (Optional) Specify tag for docker images,
    --help, -h                         (Optional) Show this usage information
EOF
}


while [[ "$#" -gt 0 ]]; do
    case "$1" in

    (--tag|-t)
            IMAGE_TAG="$2"
            shift 2
            ;;

    (--help|-h)
            usage
            shift
            exit 0
            ;;

    (--)
            shift
            break
            ;;

    (*)
            echo "error"
            exit 3
            ;;
esac
done


##############################
# build config
##############################
# BUILD_DATA_PATH="$(pwd)/kolla-ceph"
BUILD_DATA_PATH="$(cd $(dirname $0); pwd)/kolla-ceph"
BUILD_TAG_NUMBER="${BUILD_DATA_PATH}/TAG_CEPH_NUMBER"
BUILD_RECORD="${BUILD_DATA_PATH}/BUILD_CEPH_RECORD"
BUILD_LOG_PATH="${BUILD_DATA_PATH}/log"
BUILD_CONFIG="ceph-build.conf"

##############################
# image tag
##############################
if [[ -n ${IMAGE_TAG} ]]
then
    CEPH_TAG=${IMAGE_TAG}
    echo "Using specified TAG: ${CEPH_TAG} for ceph docker images."
else
    if [[ ! -d "${BUILD_DATA_PATH}" ]]; then
        sudo mkdir -p "${BUILD_DATA_PATH}"
    fi

    if [[ ! -f "${BUILD_TAG_NUMBER}" ]]; then
        echo "Both tag and ${BUILD_TAG_NUMBER} file are empty, so automatically create file with tag number 0."
        sudo sh -c "echo 0 > ${BUILD_TAG_NUMBER}"
    fi
    TAG_NUMBER=$(cat ${BUILD_TAG_NUMBER})
    ((TAG_NUMBER+=1))

    BUILD_NUMBER=$(printf %04d ${TAG_NUMBER})
    CEPH_VERSION=$(grep 'ceph_version' ${BUILD_CONFIG} | tail -1 | awk -F "=" '{print $2}')
    if [[ -z ${CEPH_VERSION} ]];then
        echo "Unable to get ceph_version in ${BUILD_CONFIG}."
        exit 1
    fi
    CEPH_RELEASE=$(grep 'ceph_release' ${BUILD_CONFIG} | tail -1 | awk -F "=" '{print $2}')
    if [[ -z ${CEPH_RELEASE} ]];then
        echo "Unable to get ceph_release in ${BUILD_CONFIG}."
        exit 1
    fi

    CEPH_TAG=${CEPH_VERSION}-${CEPH_RELEASE}.${BUILD_NUMBER}
    CEPH_TAG=${CEPH_TAG// /}
    echo "Read TAG:${CEPH_TAG} from ${BUILD_TAG_NUMBER}"
fi

##############################
# build
##############################

CMD="python kolla/cmd/build.py --config-file ${BUILD_CONFIG} --push  --tag ${CEPH_TAG}"
echo "$CMD"

BUILD_LOG_NAME="${BUILD_LOG_PATH}/build-${CEPH_TAG}.log"

if [[ ! -d "${BUILD_LOG_PATH}" ]]; then
    sudo mkdir -p "${BUILD_LOG_PATH}"
fi

# ${CMD} 2>&1 | sudo tee -a "${BUILD_LOG_NAME}"
$CMD
##############################
# judge the result
##############################
RESULT_CODE=${PIPESTATUS[0]}
if [[ ${RESULT_CODE} -eq 0 ]]; then
    if [[ -z ${IMAGE_TAG} && -f "${BUILD_TAG_NUMBER}" ]]; then
        sudo sh -c "echo ${TAG_NUMBER} > ${BUILD_TAG_NUMBER}"
    fi

    if [[ -f "${BUILD_RECORD}" ]]; then
        sudo touch "${BUILD_RECORD}"
    fi
    time=$(date +"%Y-%m-%d %H:%M.%S")
    RECORD="${time} build ceph \| tag \: \[ ${CEPH_TAG} \]"
    sudo sh -c "echo ${RECORD} >> ${BUILD_RECORD}"

    echo "Image build success: ${CEPH_TAG}"
    exit 0
else
    echo "Image build failed:${CMD}"
    exit "${RESULT_CODE}"
fi
