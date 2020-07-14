#!/bin/bash
####
# run-int.bash:
#
# Runs integration test for raspberry pi.
# Called through ssh by 31-rpi-int.bash during the running of the CI system 
####

export RPI_DIR="$(dirname ${BASH_SOURCE})/.."
export SLEEP_TIME="15"
export LOCAL_PORT="10.0.0.4"


# ./bin/*/RPI -a ${LOCAL_PORT} -p 50050 1>${LOG_DIR}/gds-logs/RPI.stdout.log 2>${LOG_DIR}/gds-logs/RPI.stderr.log &
.${RPI_DIR}/bin/*/RPI -a ${LOCAL_PORT} -p 50050 1>/dev/null 2>&1 &
GDS_PID=$!

echo "[INFO] Allowing GDS ${SLEEP_TIME} seconds to start on RPI"
sleep ${SLEEP_TIME}
# Check the above started successfully

ps -p ${GDS_PID} 2> /dev/null 1> /dev/null || exit 2 # 2 means the GDS failed to start

# Run integration tests
echo "[INFO] Running RPI/test's pytest integration tests"
cd "{RPI_DIR}/test"
timeout --kill-after=10s 240s pytest
RET_PYTEST=$?

# kill the remaining processes and exit with the return code
pkill -P $GDS_PID
kill $GDS_PID
sleep 2
pkill -KILL RPI
exit ${RET_PYTEST}