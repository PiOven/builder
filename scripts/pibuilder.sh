#!/bin/sh

set -e

CACHE_DIR="./cache"
RESULT_FILE="${CACHE_DIR}/result"
SETTINGS_FILE="./settings.sh"
BOOT_DIR="/media/rpi_boot"
ROOT_DIR="/media/rpi_root"
UNZIP_TARGET="${CACHE_DIR}/os.img"

download () {
  # Add an MD5 sum on the filename to ensure we have the correct file
  SRC=${1}
  SUM=$(printf '%s' $SRC | md5sum | cut -d ' ' -f 1)

  TARGET="${CACHE_DIR}/os.${SUM}.zip"

  if [ ! -f "${TARGET}" ]; then
    curl -L ${SRC} -o ${TARGET}
  fi

  rm -f ${UNZIP_TARGET}
  unzip -o ${TARGET} -d "${CACHE_DIR}/unzip"
  mv ${CACHE_DIR}/unzip/* ${UNZIP_TARGET}
  rm -Rf "${CACHE_DIR}/unzip"

  sleep 5
}

padNumber () {
  NUMBER=${1}
  printf "%03d\n" ${NUMBER}
}

if [ $UID != 0 ]; then
  echo 'Script must be run as root'
  exit 1
fi

rm -f ${RESULT_FILE}

# Create directories to mount the images to
mkdir -p ${BOOT_DIR} ${ROOT_DIR}

if [ ! -f "${SETTINGS_FILE}" ]; then
  # Running setup first
  make setup
fi

# Load up the variables
source ${SETTINGS_FILE}

# Generate the password
PI_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# Download the operating system
download ${PI_OS}

LOOP=$(kpartx -va ${UNZIP_TARGET})

MOUNT_POINTS=$(echo ${LOOP} | grep -ioE 'loop(\w+)')

umount ${BOOT_DIR} || true
umount ${ROOT_DIR} || true

while read -r line; do
  if [[ $line == *"p1" ]]; then
    mount "/dev/mapper/${line}" ${BOOT_DIR} -o ro --rw
  elif [[ $line == *"p2" ]]; then
    mount "/dev/mapper/${line}" ${ROOT_DIR} -o ro --rw
  fi
done <<< "$MOUNT_POINTS"

sleep 5

# Enable SSH
touch ${BOOT_DIR}/ssh

# Configure WIFI
if ! (grep -q "ssid=" "${ROOT_DIR}/etc/wpa_supplicant/wpa_supplicant.conf"); then
  printf "\nnetwork={\n  ssid=\"%s\"\n  psk=\"%s\"\n}\n" ${PI_WIFI_SSID} ${PI_WIFI_PASS} >> ${ROOT_DIR}/etc/wpa_supplicant/wpa_supplicant.conf
fi

# Set the first boot script
if ! (grep -q "./scripts/setup.sh" "${ROOT_DIR}/etc/rc.local"); then
  sed -i '$ d' "${ROOT_DIR}/etc/rc.local"
  printf "if [ -f /setup.sh ]; then\n  printf 'Setting up the Pi\n'\n  sh /setup.sh\nfi\n\n  printf 'Pi setup\n'\nexit 0" >> "${ROOT_DIR}/etc/rc.local"
fi

cp ./scripts/setup.sh "${ROOT_DIR}/setup.sh"
sed -i "s/%PI_HOSTNAME%/$PI_HOSTNAME/g" "${ROOT_DIR}/setup.sh"
sed -i "s/%PI_USERNAME%/$PI_USERNAME/g" "${ROOT_DIR}/setup.sh"
sed -i "s/%PI_PASSWORD%/$PI_PASSWORD/g" "${ROOT_DIR}/setup.sh"
sed -i "s/%PI_PASSWORD%/$PI_WIFI_SSID/g" "${ROOT_DIR}/setup.sh"
chmod 755 "${ROOT_DIR}/setup.sh"
cp "${PI_SSH_KEY}" "${ROOT_DIR}/id_rsa.pub"

umount ${BOOT_DIR} || true
umount ${ROOT_DIR} || true

kpartx -d ${UNZIP_TARGET}

echo "username: ${PI_USERNAME}" >> "${RESULT_FILE}"
echo "password: ${PI_PASSWORD}" >> "${RESULT_FILE}"

echo "--- Finished successfully ---"
echo "username: ${PI_USERNAME}"
echo "password: ${PI_PASSWORD}"
echo "-----------------------------"
