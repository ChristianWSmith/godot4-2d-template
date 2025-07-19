#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BUILD_DIR="${SCRIPT_DIR}/build"
mkdir -p "${BUILD_DIR}"

BUILD_TYPE="${1:-debug}"
BUILD_TYPE="${BUILD_TYPE,,}"

case "${BUILD_TYPE}" in
    debug)
        BUILD_TYPE_ARG="--export-debug"
        ;;
    release)
        BUILD_TYPE_ARG="--export-release"
        ;;
    *)
        echo "Unsupported build type: ${BUILD_TYPE}"
        exit 1
esac


# Get the platform
platform="$(uname -s)"
case "${platform}" in
    Linux*)
        TARGET="Linux"
        ARTIFACT="game"
        ;;
    Darwin*)
        TARGET="macOS"
        ARTIFACT="game.app"
        ;;
    CYGWIN*|MINGW*)
        TARGET="Windows Desktop"
        ARTIFACT="game.exe"
        ;;
    *)
        echo "Unsupported platform: ${platform}"
        exit 1
esac

"${SCRIPT_DIR}/start.sh" --headless $BUILD_TYPE_ARG "${TARGET}" "build/${ARTIFACT}"
