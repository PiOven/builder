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

  mkdir -p ${CACHE_DIR}

  TARGET="${CACHE_DIR}/os.${SUM}.zip"

  if [ ! -f "${TARGET}" ]; then
    curl -L ${SRC} -o ${TARGET}
  fi

  rm -f ${UNZIP_TARGET}
  unzip -o ${TARGET} -d "${CACHE_DIR}/unzip"
  mv ${CACHE_DIR}/unzip/* ${UNZIP_TARGET}
  rm -Rf "${CACHE_DIR}/unzip"

  sleep 1
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
  echo "Please add configuration to ${SETTINGS_FILE}"
  exit 1
fi

# Load up the variables
source ${SETTINGS_FILE}

# Validate the settings
if [[ -z "${PI_HOSTNAME}" ]]; then
  echo "PI_HOSTNAME needs to be configured with your desired hostname"
  exit 1
fi

if [[ -z "${PI_SSH_KEY}" ]]; then
  echo "PI_SSH_KEY needs to be configured with your desired SSH key"
  exit 1
fi

if ! [[ -f "${PI_SSH_KEY}" ]]; then
  echo "PI_SSH_KEY (${PI_SSH_KEY}) is not a file"
  exit 1
fi

if [[ -z "${PI_USERNAME}" ]]; then
  echo "PI_USERNAME needs to be configured with your designed username"
  exit 1
fi

# Generate the password
PI_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${PI_PASSWORD_LENGTH} | head -n 1)

# Download the operating system
download ${PI_OS}

LOOP=$(kpartx -sva ${UNZIP_TARGET})

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

sleep 1

# Enable SSH
touch ${BOOT_DIR}/ssh

# Configure WiFi - if required
if [[ "${PI_WIFI_SSID}" && "${PI_WIFI_PASS}" ]]; then
  if ! (grep -q "ssid=" "${ROOT_DIR}/etc/wpa_supplicant/wpa_supplicant.conf"); then
    printf "\nnetwork={\n  ssid=\"%s\"\n  psk=\"%s\"\n}\n" ${PI_WIFI_SSID} ${PI_WIFI_PASS} >> ${ROOT_DIR}/etc/wpa_supplicant/wpa_supplicant.conf
  fi
fi

# Set the first boot script
if ! (grep -q "./scripts/first_run.sh" "${ROOT_DIR}/etc/rc.local"); then
  sed -i '$ d' "${ROOT_DIR}/etc/rc.local"
  printf "if [ -f /first_run.sh ]; then\n  printf 'Setting up the Pi'\n  sh /first_run.sh\n  reboot\n\n  printf 'Pi setup'\nfi\n\nexit 0\n" >> "${ROOT_DIR}/etc/rc.local"
fi

cp ./scripts/first_run.sh "${ROOT_DIR}/first_run.sh"
sed -i "s/%PI_HOSTNAME%/$PI_HOSTNAME/g" "${ROOT_DIR}/first_run.sh"
sed -i "s/%PI_USERNAME%/$PI_USERNAME/g" "${ROOT_DIR}/first_run.sh"
sed -i "s/%PI_PASSWORD%/$PI_PASSWORD/g" "${ROOT_DIR}/first_run.sh"
sed -i "s/%PI_WIFI_SSID%/$PI_WIFI_SSID/g" "${ROOT_DIR}/first_run.sh"
sed -i "s/%PI_MAILGUN_API_KEY%/$PI_MAILGUN_API_KEY/g" "${ROOT_DIR}/first_run.sh"
sed -i "s/%PI_MAILGUN_DOMAIN%/$PI_MAILGUN_DOMAIN/g" "${ROOT_DIR}/first_run.sh"
sed -i "s/%PI_EMAIL_ADDRESS%/$PI_EMAIL_ADDRESS/g" "${ROOT_DIR}/first_run.sh"
sed -i "s/%PI_INSTALL_DOCKER%/$PI_INSTALL_DOCKER/g" "${ROOT_DIR}/first_run.sh"
sed -i "s/%PI_GPU_MEMORY%/$PI_GPU_MEMORY/g" "${ROOT_DIR}/first_run.sh"
sed -i "s/%PI_IP_ADDRESS_RANGE_START%/$PI_IP_ADDRESS_RANGE_START/g" "${ROOT_DIR}/first_run.sh"
sed -i "s/%PI_IP_ADDRESS_RANGE_END%/$PI_IP_ADDRESS_RANGE_END/g" "${ROOT_DIR}/first_run.sh"
sed -i "s/%PI_DNS_ADDRESS%/$PI_DNS_ADDRESS/g" "${ROOT_DIR}/first_run.sh"

chmod 755 "${ROOT_DIR}/first_run.sh"
cp "${PI_SSH_KEY}" "${ROOT_DIR}/id_rsa.pub"
cp -Rf ./data "${ROOT_DIR}/opt/data"
cp -Rf ./scripts/interfaces.py "${ROOT_DIR}/interfaces.py"
cp ./files/hosts "${ROOT_DIR}/etc/hosts"

# Set the crontab to update on a daily basis
cp ./files/update.sh "${ROOT_DIR}/etc/cron.daily/update"
chmod 755 "${ROOT_DIR}/etc/cron.daily/update"

rm "${ROOT_DIR}/etc/motd"
cp ./files/motd.sh "${ROOT_DIR}/etc/profile.d/motd.sh"
chmod 755 "${ROOT_DIR}/etc/profile.d/motd.sh"

# Clean up after ourselves
umount ${BOOT_DIR} || true
umount ${ROOT_DIR} || true

kpartx -d ${UNZIP_TARGET}

echo "username: ${PI_USERNAME}" >> "${RESULT_FILE}"
echo "password: ${PI_PASSWORD}" >> "${RESULT_FILE}"

echo "--- Finished successfully ---"
echo "username: ${PI_USERNAME}"
echo "password: ${PI_PASSWORD}"
echo "-----------------------------"
