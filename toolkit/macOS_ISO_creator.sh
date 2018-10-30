#!/bin/sh
# macOS ISO creator
# Original author: shela | https://www.insanelymac.com/forum/profile/483646-shela/
# 
# Support for High Sierra and Mojave added by thelamehacker@GitHub | https://github.com/thelamehacker
#
# License: GNU General Public License v3.0
# Release date: 30 October 2018
# Last updated: 30 October 2018
# Version: 0.1a
# -----------------------------------------------------------------------------


#######################################
# Declarations
#######################################
shopt -s nocasematch
readonly TEMP_DIR=$(mktemp -d /tmp/osx-image.XXX)
readonly INPUT_MOUNT="${TEMP_DIR}/input_mount"
readonly OUTPUT_MOUNT="${TEMP_DIR}/output_mount"
readonly BUILD_MOUNT="${TEMP_DIR}/build_mount"
readonly SPARSE_IMAGE="${TEMP_DIR}/osx.sparseimage"
readonly DEFAULT_OUTPUT_DIR="${HOME}/Desktop"

trap cleanup EXIT

#######################################
# Display information message
#######################################
info() {
  echo -e "\033[0;32m${1}\033[0m"
}

#######################################
# Display error message
#######################################
error() {
  echo -e "\033[0;31m${1}\033[0;39m" >&2
}

#######################################
# Create install iso image
#######################################
create_image() {
  local in=${1}
  local out=${2%/}

  # Create output directory
  if [ ! -d "${out}" ]; then
    info "Destination directory ${out} does not exists. Creating..."
    mkdir -p "${out}"
    if [[ $? -ne 0 ]]; then
      error "Could not create output directory."
      exit 1
    fi
  fi

  # Mount the installer image
  info "Attaching $(basename "${in}")..."
  hdiutil attach "${in}" -noverify -nobrowse -mountpoint "${INPUT_MOUNT}"
  if [[ $? -ne 0 ]]; then
    error "Could not mount $(basename "${in}")."
    exit 1
  fi

  # Create sparse image with a Single Partition UDIF
  info "Creating sparse image..."
  hdiutil create -o "${TEMP_DIR}/osx" -size 7500g -type SPARSE -layout SPUD -fs HFS+J
  if [[ $? -ne 0 ]]; then
    error "Could not create sparse image."
    exit 1
  fi

  # Mount the sparse image
  info "Mounting sparse image..."
  hdiutil attach "${SPARSE_IMAGE}" -noverify -nobrowse -mountpoint "${BUILD_MOUNT}"
  if [[ $? -ne 0 ]]; then
    error "Could not attach sparse image."
    exit 1
  fi

  # Restore the Base System into the sparse image
  info "Restoring BaseSystem.dmg..."
  asr restore -source "${INPUT_MOUNT}/BaseSystem.dmg" -target "${BUILD_MOUNT}" -noprompt -noverify -erase
  if [[ $? -ne 0 ]]; then
    error "Could not mount BaseSystem.dmg."
    exit 1
  fi

  if [[ -d "/Volumes/OS X Base System" ]]; then
    declare -r BASE_SYSTEM_PATH="/Volumes/OS X Base System"
  else
    # for Mac OS X Lion
    declare -r BASE_SYSTEM_PATH="/Volumes/Mac OS X Base System"
  fi
  declare -r PLIST="${BASE_SYSTEM_PATH}/System/Library/CoreServices/SystemVersion.plist"

  # Get installer OS product version
  local os_version
  os_version=$(/usr/libexec/PlistBuddy -c "Print :ProductVersion" "${PLIST}")
  if [[ $? -ne 0 ]]; then
    error "Could not get Product Version."
    exit 1
  fi

  # Get installer OS product build version
  local os_build
  os_build=$(/usr/libexec/PlistBuddy -c "Print :ProductBuildVersion" "${PLIST}")
  if [[ $? -ne 0 ]]; then
    error "Could not get Product Build Version."
    exit 1
  fi
  info "Detected OS X version: ${os_version}, build ${os_build}"
  declare -r FILE_PATH="${out}/OS.X.${os_version}.${os_build}"

  # Remove Packages link and replace with actual files
  info "Replacing Packages link with actual files..."
  rm "${BASE_SYSTEM_PATH}/System/Installation/Packages"
  if [[ $? -ne 0 ]]; then
    error "Could not remove Packages link."
    exit 1
  fi

  cp -rp "${INPUT_MOUNT}/Packages" "${BASE_SYSTEM_PATH}/System/Installation/"
  if [[ $? -ne 0 ]]; then
    error "Could not replace Packages link with actual files."
    exit 1
  fi

  # Copy installer dependencies
  info "Copying dependency files..."
  cp -rp "${INPUT_MOUNT}/BaseSystem.chunklist" "${BASE_SYSTEM_PATH}/BaseSystem.chunklist"
  if [[ $? -ne 0 ]]; then
    error "Could not copy dependency files."
    exit 1
  fi

  cp -rp "${INPUT_MOUNT}/BaseSystem.dmg" "${BASE_SYSTEM_PATH}/BaseSystem.dmg"
  if [[ $? -ne 0 ]]; then
    error "Could not copy dependency files."
    exit 1
  fi

  # Unmount the Base System image
  hdiutil detach "${BASE_SYSTEM_PATH}"

  # Unmount the installer image
  hdiutil detach "${INPUT_MOUNT}"

  # Convert sparse image to iso
  info "Creating iso image..."
  hdiutil convert "${SPARSE_IMAGE}" -format UDTO -o "${FILE_PATH}"
  if [[ $? -ne 0 ]]; then
    error "Could not create iso image."
    exit 1
  fi

  # Rename the cdr image
  info "Renaming cdr image..."
  mv "${FILE_PATH}.cdr" "${FILE_PATH}.iso"
  if [[ $? -ne 0 ]]; then
    error "Could not rename cdr image."
    exit 1
  fi

  # Show completion message
  info "Complete!!!"
  #info "  Path of dmg image: ${FILE_PATH}.dmg"
  info "  Path of iso image: ${FILE_PATH}.iso"
}

#######################################
# Cleanup directories and files
#######################################
cleanup() {
  if [[ -d "${BUILD_MOUNT}" ]]; then
    hdiutil detach "${BUILD_MOUNT}"
  fi

  if [[ -d "${OUTPUT_MOUNT}" ]]; then
    hdiutil detach "${OUTPUT_MOUNT}"
  fi

  if [[ -d "${INPUT_MOUNT}" ]]; then
    hdiutil detach "${INPUT_MOUNT}"
  fi

  if [[ -f "${SPARSE_IMAGE}" ]]; then
    rm "${SPARSE_IMAGE}"
  fi

  rmdir "${TEMP_DIR}"

  shopt -u nocasematch
}

#######################################
# main
#######################################
main() {
  echo -e "\033[1;4mOS X Install ISO Creater\033[0m"
  cat << EOT

Support OS X Version: 10.6, 10.7, 10.8, 10.9, 10.10, 10.11, 10.12, 10.13 and 10.14

You need to download macOS Installer (also known as Mac OS X till version 10.11) from the Mac App Store and save it to the Application folder - its default location.
Or, you can create iso from InstallESD.dmg you specified.

EOT

  declare -a menu_items=("Mac OS X 10.7 (Lion)" \
                         "OS X 10.8   (Mountain Lion)" \
                         "OS X 10.9   (Mavericks)" \
                         "OS X 10.10  (Yosemite)" \
                         "OS X 10.11  (El Capitan)" \
                         "macOS 10.12 (Sierra)" \
                         "macOS 10.13 (High Sierra)" \
                         "macOS 10.14 (Mojave)")
  declare -a osx_names=("Mac OS X Lion" \
                        "OS X Mountain Lion" \
                        "OS X Mavericks" \
                        "OS X Yosemite" \
                        "OS X El Capitan" \
                        "macOS Sierra" \
                        "macOS High Sierra" \
                        "macOS Mojave")
  declare -r DMG_PATH_HEAD="/Applications/Install "
  declare -r DMG_PATH_TAIL=".app/Contents/SharedSupport/InstallESD.dmg"
  local -i i=0
  local dmg_path
  local output_dir

  # Check if installer exists
  for name in "${osx_names[@]}"; do
    dmg_path="${DMG_PATH_HEAD}${name}${DMG_PATH_TAIL}"
    if [[ ! -f "${dmg_path}" ]]; then
      unset menu_items[${i}]
      unset osx_names[${i}]
    fi
    let i++
  done

  # Remove non-existent versions from array
  menu_items=("${menu_items[@]}")
  osx_names=("${osx_names[@]}")

  # Display menu items
  i=0
  if [[ ${#menu_items[@]} -eq 0 ]]; then
    echo -e "No macOS/OS X installer found."
    echo -e "Please Select:"
  else
    echo "Following ${#menu_items[@]} macOS/OS X installer(s) found."
    echo -e "Please Select:\n"
    for name in "${menu_items[@]}"; do
      echo "$((i + 1))) ${menu_items[${i}]}"
      let i++
    done
  fi
  echo -e "\n0) Specifiy InstallESD.dmg path"
  echo -e "\nq) Quit\n"

  # Read user selection
  while : ; do
    read -rp $'\e[1m'"Enter a number or 'q': "$'\e[0m' selection
    if [ "${selection}" -eq 0 ] 2> /dev/null; then
      read -ep $'\e[1m'"Enter the InstallESD.dmg path: "$'\e[0m' dmg_path
      break
    elif [ "${selection}" -gt 0 ] 2> /dev/null && [ "${selection}" -le ${i} ] 2> /dev/null; then
      dmg_path="${DMG_PATH_HEAD}${osx_names[$((selection - 1))]}${DMG_PATH_TAIL}"
      break
    elif [ "${selection}" = "q" ]; then
      exit
      break
    fi
  done

  # Read user output directory
  read -ep $'\e[1m'"Enter the output directory (default: ${DEFAULT_OUTPUT_DIR}): "$'\e[0m' output_dir
  if [[ -z "${output_dir}" ]]; then
    output_dir="${DEFAULT_OUTPUT_DIR}"
  fi

  create_image "${dmg_path}" "${output_dir}"
}

main