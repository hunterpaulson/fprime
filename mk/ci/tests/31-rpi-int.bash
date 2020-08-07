#!/bin/bash
####
# 30-ints.bash:
#
# Integration test for the raspberry pi
####
export SCRIPT_DIR="$(dirname ${BASH_SOURCE})/.."
export WORKDIR="$(cd ${SCRIPT_DIR}/../../RPI; pwd)"
. "${SCRIPT_DIR}/helpers.bash"

export SLEEP_TIME="10"

# Modify the user, hostname, and local to run this on future Raspberry pi's and local machines
# also this is designed to run with ssh keys and NOT passwords
export USER="pi"
export HOSTNAME="10.0.0.31"
export LOCAL="10.0.0.7" 


mkdir -p "${LOG_DIR}/rpi-logs"

# compile the binary for the raspberry pi
echo "[INFO] Running headless GDS"
fprime-gds -n -d "${WORKDIR}" -g none -l "${LOG_DIR}/gds-logs" 1>${LOG_DIR}/rpi-logs/fprime-gds.rpi.stdout.log 2>${LOG_DIR}/rpi-logs/fprime-gds.rpi.stderr.log &
GDS_PID=$!

echo "[INFO] Allowing GDS ${SLEEP_TIME} seconds to start locally"
sleep ${SLEEP_TIME}

# scp the compiled binary up to the raspberry pi
echo "[INFO] Copying binary to remote raspberry pi"
scp ${WORKDIR}/bin/*/RPI ${USER}@${HOSTNAME}:/home/${USER}

echo "[INFO] Running binary on remote raspberry pi"
ssh ${USER}@${HOSTNAME} 'nc -l 50000 & ~/RPI -a 10.0.0.7 -p 50000' &
# RET_REMOTE=$?

echo "[INFO] Allowing GDS ${SLEEP_TIME} seconds to start on RPI"
sleep ${SLEEP_TIME}

echo "[INFO] Running RPI/test's pytest integration tests"
cd "${WORKDIR}/test"

# currently the test takes roughly 10 minuntes 
# it also fails since the integration test we are running was designed for the Ref app
# timeout --kill-after=10s 240s pytest 
pytest
RET_PYTEST=$?

# Timeout Exit Codes
# 0 | Everything worked and pytest integration test passed
# 1 | GDS compiled and ran, however pytest integration test failed
# 2 | GDS failed to start
# 124 | Pytest took too long and was automatically timed out after 240 seconds

# kill the remaining processes and exit with the return code
pkill -P $GDS_PID
kill $GDS_PID
sleep 2
ssh ${USER}@${HOSTNAME} 'killall RPI'
if [ ${RET_PYTEST} -eq 1 ]; then 
    fail_and_stop "Integration test on raspberry pi failed"
elif [ ${RET_PYTEST} -eq 2 ]; then 
    fail_and_stop "GDS on raspberry pi failed to start"
elif [ ${RET_PYTEST} -eq 124 ]; then 
    fail_and_stop "Integration test took too long and was automatically timed out"
fi
exit ${RET_PYTEST}