#!/usr/bin/env bash
set -euo pipefail


# Setup
GREEN='\033[0;32m'
NC='\033[0m'
LOG_PREFIX="${GREEN}[$(basename "${0}")]${NC}"

log() {
    echo -e "${LOG_PREFIX} ${@}"
}


# Get context
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
log "Root Dir: ${SCRIPT_DIR}"
GODOT_VERSION="$(cat "${SCRIPT_DIR}/.godot-version")"
log "Godot Version: ${GODOT_VERSION}"
EDITOR_DIR="${SCRIPT_DIR}/.editor"
mkdir -p "${EDITOR_DIR}"
EXPORT_TEMPLATES_DIR="${EDITOR_DIR}/editor_data/export_templates/$(echo "${GODOT_VERSION}" | tr '-' '.')"

if [ ! -e "${EDITOR_DIR}/.godot-version" ] || [ "${GODOT_VERSION}" != "$(cat "${EDITOR_DIR}/.godot-version")" ]; then
    log "Version changed, cleaning..."
    rm -rf "${EDITOR_DIR}"
    mkdir -p "${EDITOR_DIR}"
    cp "${SCRIPT_DIR}/.godot-version" "${EDITOR_DIR}/.godot-version"
fi

# Get the platform
platform="$(uname -s)"
log "Platform: ${platform}"
case "${platform}" in
    Linux*)          PLATFORM_SUFFIX="linux.x86_64";;
    Darwin*)         PLATFORM_SUFFIX="macos.universal";;
    CYGWIN*|MINGW*)  PLATFORM_SUFFIX="win64.exe";;
    *)
        echo "Unsupported platform: ${platform}"
        exit 1
esac


# Ensure we have the engine
log "Checking for engine..."
ENGINE_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_${PLATFORM_SUFFIX}.zip"
touch "${EDITOR_DIR}/._sc_"
ENGINE_DOWNLOAD_FILE="${EDITOR_DIR}/$(basename "${ENGINE_URL}")"

if [[ "${platform}" =~ ^"Darwin" ]]; then
    EDITOR="${EDITOR_DIR}/Godot_v${GODOT_VERSION}.app"
else
    EDITOR="${EDITOR_DIR}/Godot_v${GODOT_VERSION}_${PLATFORM_SUFFIX}"
fi

if [ ! -e "${EDITOR}" ]; then
    log "Engine not found, checking for archive..."
    if [ ! -e "${ENGINE_DOWNLOAD_FILE}" ]; then
        log "Archive not found, downloading..."
        wget -O "${ENGINE_DOWNLOAD_FILE}" "${ENGINE_URL}" -q --show-progress
    else
        log "Archive found: ${ENGINE_DOWNLOAD_FILE}"
    fi
    pushd "${EDITOR_DIR}" > /dev/null 2>&1
    log "Extracting engine..."
    unzip "${ENGINE_DOWNLOAD_FILE}" > /dev/null 2>&1
    if [[ "${platform}" =~ ^"Darwin" ]]; then
        mv "Godot.app" "$(basename "${EDITOR}")"
    fi
    popd > /dev/null 2>&1

    chmod +x "${EDITOR}"
else
    log "Engine found: ${EDITOR}"
fi


# Ensure we have the export templates
log "Checking for export templates..."
EXPORT_TEMPLATES_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz"
EXPORT_TEMPLATES_DOWNLOAD_FILE="${EDITOR_DIR}/$(basename "${EXPORT_TEMPLATES_URL}")"

if [ ! -e "${EXPORT_TEMPLATES_DIR}" ]; then
    log "Export templates not found, checking for archive..."
    pushd "${EDITOR_DIR}" > /dev/null 2>&1
    if [ ! -e "${EXPORT_TEMPLATES_DOWNLOAD_FILE}" ]; then
        log "Archive not found, downloading..."
        wget -O "${EXPORT_TEMPLATES_DOWNLOAD_FILE}" "${EXPORT_TEMPLATES_URL}" -q --show-progress
    else
        log "Archive found: ${EXPORT_TEMPLATES_DOWNLOAD_FILE}"
    fi
    log "Extracting export templates..."
    unzip "${EXPORT_TEMPLATES_DOWNLOAD_FILE}" > /dev/null 2>&1
    mkdir -p "${EXPORT_TEMPLATES_DIR}"
    mv templates/* "${EXPORT_TEMPLATES_DIR}"
    rm -rf templates
    popd > /dev/null 2>&1
else
    log "Export templates found: ${EXPORT_TEMPLATES_DIR}"
fi


# Start the editor
if [[ "${platform}" =~ ^"Darwin" ]]; then
    open "${EDITOR}" "${SCRIPT_DIR}/project.godot" --args "$@"
else
    "${EDITOR}" "${SCRIPT_DIR}/project.godot" "$@"
fi
