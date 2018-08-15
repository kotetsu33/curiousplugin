#!/bin/bash

LOG_FILE=/tmp/bbb

echo "arecord started." | tee -a ${LOG_FILE}

echo "arecord $1 $2 $3 $4 $5 $6 $7 $8 $9" | tee -a ${LOG_FILE}
nohup /usr/bin/arecord $1 $2 $3 $4 $5 $6 $7 $8 $9 &

echo "arecord finished." | tee -a ${LOG_FILE}

exit 0
