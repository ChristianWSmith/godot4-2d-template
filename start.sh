#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

GODOT_VERSION="$(cat "${SCRIPT_DIR}/.godot-version")"

uname_out="$(uname -s)"
case "${uname_out}" in
    Linux*)          PLATFORM_SUFFIX="linux.x86_64";;
    Darwin*)         PLATFORM_SUFFIX="macos.universal";;
    CYGWIN*|MINGW*)  PLATFORM_SUFFIX="win64.exe";;
    *)
        echo "Unsupported platform: ${uname_out}"
        exit 1
esac

URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_${PLATFORM_SUFFIX}.zip"
EDITOR_DIR="${SCRIPT_DIR}/.editor"
DOWNLOAD_FILE="${EDITOR_DIR}/$(basename "${URL}")"

if [[ "${uname_out}" =~ ^"Darwin" ]]; then
    EDITOR="${EDITOR_DIR}/Godot_v${GODOT_VERSION}.app"
else
    EDITOR="${EDITOR_DIR}/Godot_v${GODOT_VERSION}_${PLATFORM_SUFFIX}"
fi

if [ ! -e "${EDITOR}" ]; then
    if [ ! -e "${DOWNLOAD_FILE}" ]; then
        wget -O "${DOWNLOAD_FILE}" "${URL}"
    fi
    pushd "${EDITOR_DIR}"
    unzip "${DOWNLOAD_FILE}"
    if [[ "${uname_out}" =~ ^"Darwin" ]]; then
        mv "Godot.app" "$(basename "${EDITOR}")"
    fi
    popd

    chmod +x "${EDITOR}"
fi

if [[ "${uname_out}" =~ ^"Darwin" ]]; then
    open "${EDITOR}" "${SCRIPT_DIR}/project.godot" "$@"
else
    "${EDITOR}" "${SCRIPT_DIR}/project.godot" "$@"
fi
