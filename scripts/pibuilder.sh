#!/bin/sh

set -e

CACHE_DIR="./cache"
SETTINGS_FILE="${CACHE_DIR}/settings.sh"
BOOT_DIR="/media/rpi_boot"
ROOT_DIR="/media/rpi_root"
TARGET="${CACHE_DIR}/os.zip"
UNZIP_TARGET="${CACHE_DIR}/os.img"

download () {
  SRC=${1}

  if [ ! -f "${TARGET}" ]; then
    curl -L ${SRC} -o ${TARGET}
  fi

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

for i in `seq 1 ${PI_INSTANCE_COUNT}`
do
  INST_NUM=$(padNumber ${i})

  IMG_FILE="${UNZIP_TARGET/.img/-$INST_NUM}.img"
  TARGET_HOSTNAME="${PI_HOSTNAME}-${INST_NUM}"

  rm "${IMG_FILE}" || true

  cp ${UNZIP_TARGET} ${IMG_FILE}

  kpartx -va ${IMG_FILE}

  umount ${BOOT_DIR} || true
  umount ${ROOT_DIR} || true

  # @todo get the loop value from kpartx
  mount /dev/mapper/loop2p1 ${BOOT_DIR} -o ro --rw
  mount /dev/mapper/loop2p2 ${ROOT_DIR} -o ro --rw

  sleep 5

  # Enable SSH
  touch ${BOOT_DIR}/ssh

  # Configure WIFI
  if ! (grep -q "ssid=" "${ROOT_DIR}/etc/wpa_supplicant/wpa_supplicant.conf"); then
    printf "\nnetwork={\n  ssid=\"%s\"\n  psk=\"%s\"\n}\n" ${PI_WIFI_SSID} ${PI_WIFI_PASS} >> ${ROOT_DIR}/etc/wpa_supplicant/wpa_supplicant.conf
  fi

  # Configure hostname
  echo "${TARGET_HOSTNAME}" > "${ROOT_DIR}/etc/hostname"

  HOST_FILE=$(cat "${ROOT_DIR}/etc/hosts")
  OLD_HOST="raspberrypi"
  echo "${HOST_FILE//$OLD_HOST/$TARGET_HOSTNAME}" > "${ROOT_DIR}/etc/hosts"

  # Set the first boot script
  if ! (grep -q "./scripts/firstrun-config.sh" "${ROOT_DIR}/etc/rc.local"); then
    sed -i '$ d' "${ROOT_DIR}/etc/rc.local"
    printf "if [ -f /firstrun-config.sh ]; then\n  sh /firstrun-config.sh\nfi\n\nexit 0" >> "${ROOT_DIR}/etc/rc.local"
  fi

  cp ./scripts/firstrun-config.sh "${ROOT_DIR}/firstrun-config.sh"
  sed -i "s/%USERNAME%/$PI_USERNAME/g" "${ROOT_DIR}/firstrun-config.sh"
  sed -i "s/%PASSWORD%/$PI_PASSWORD/g" "${ROOT_DIR}/firstrun-config.sh"
  chmod 755 "${ROOT_DIR}/firstrun-config.sh"
  cp ${PI_SSH_KEY} "${ROOT_DIR}/id_rsa.pub"

  umount ${BOOT_DIR} || true
  umount ${ROOT_DIR} || true

  kpartx -d ${IMG_FILE}

  sleep 5
done

echo "--- Finished successfully ---"
echo "instances: ${PI_INSTANCE_COUNT}"
echo "username: ${PI_USERNAME}"
echo "password: ${PI_PASSWORD}"
echo "-----------------------------"
