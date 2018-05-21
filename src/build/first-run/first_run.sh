#!/usr/bin/env bash

#>> /var/log/rc.local.log exec 2>&1

set -e

###
# This is a series of tasks that need to
# happen when the Pi is booted for the first
# time.
#
# These are written and executed as single,
# repeatable tasks so that the Pi will still
# work correctly should in case power is lost
# at any point before it finishes.
###

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

log ()
{
  while read data; do
    echo "[`date --iso-8601=seconds`]: ${data}";
  done;
}

piTask ()
{
  FILE=${CWD}/$1
  EXECUTABLE=$2

  if [ -z ${EXECUTABLE} ]; then
    echo "Defaulting EXECUTABLE to bash" | log
    EXECUTABLE="bash"
  fi

  echo "Looking for file ${FILE}" | log

  if [ -f ${FILE} ]; then
    echo "File ${FILE} exists - executing with ${EXECUTABLE}" | log
    ${EXECUTABLE} ${FILE} | log
    RETVAL_BASH="${PIPESTATUS[0]}"

    if [ ${RETVAL_BASH} != 0 ]; then
      echo "Exiting with code ${RETVAL_BASH}" | log
      exit ${RETVAL_BASH}
    fi
  else
    # This could be thought of as an error, but let's assume this task has been done
    echo "File ${FILE} doesn't exist - task has run" | log
  fi
}

echo "=== Start of Tasks ===" | log

# Set envvars needed for build - not configuration
export TARGET_IP="/tmp/target_ip"
export NETWORK_CONFIG="/etc/network/interfaces"

# Run the tasks in order
piTask "./tasks/01-user-management.sh"
piTask "./tasks/02-install-py-deps.sh"
piTask "./tasks/03-configure-ip.py" "python"
piTask "./tasks/04-remove-py-deps.sh"

#piTask "./tasks/99-delete-pioven.sh"

echo "=== End of Tasks ===" | log
