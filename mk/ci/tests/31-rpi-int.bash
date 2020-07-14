#!/bin/bash
####
# 30-ints.bash:
#
# Integration test for the raspberry pi
####
export SCRIPT_DIR="$(dirname ${BASH_SOURCE})/.."
. "${SCRIPT_DIR}/helpers.bash"

# Modify the user and hostname to run this on future Raspberry pi's
# also this is designed to run with ssh keys and NOT passwords
export USER="hypnos"
export HOSTNAME="10.0.0.31"

# mkdir -p "${LOG_DIR}/rpi-logs"

# compile the binary for the raspberry pi IN THE FOREGROUND SO WE CAN SCP WHEN DONE
echo "[INFO] Compiling headless GDS layer for RPI"
fprime-gds -n -d "${FPRIME_DIR}/RPI" -g none -l "${LOG_DIR}/gds-logs" 1>${LOG_DIR}/gds-logs/fprime-gds.rpi.stdout.log 2>${LOG_DIR}/gds-logs/fprime-gds.rpi.stderr.log
# GDS_PID=$!
# scp the compiled binary up to the raspberry pi
echo "[INFO] Copying binary to remote raspberry pi"
scp /bin/*/RPI ${USER}@${HOSTNAME}:/home/hypnos/fprime/RPI

echo "[INFO] Running binary and integration test on remote raspberry pi"
local REMOTE_OUTPUT
REMOTE_OUTPUT=$(
    ssh ${USER}@${HOSTNAME} ~/fprime/RPI/scripts/run-int.sh
)
RET_REMOTE=$?

# Remote Script Exit Codes
# 0 | Everything worked and pytest integration test passed
# 1 | GDS compiled and ran, however pytest integration test failed
# 2 | GDS failed to start
# 124 | Pytest took too long and was automatically timed out after 240 seconds

# pkill -P $GDS_PID
# kill $GDS_PID
# sleep 2
# pkill -KILL RPI
if [ ${RET_REMOTE} -eq 1 ]; then 
    fail_and_stop "Integration test on raspberry pi failed"
elif [ ${RET_REMOTE} -eq 2 ]; then 
    fail_and_stop "GDS on raspberry pi failed to start"
elif [ ${RET_REMOTE} -eq 124 ]; then 
    fail_and_stop "Integration test took too long and was automatically timed out"
fi
exit ${RET_REMOTE}