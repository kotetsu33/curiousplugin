#!/bin/bash

# init
SCRIPT_DIR=$(cd $(dirname $0); pwd)
start=0
end=15
cnt=0
distance=15

PRINTER_ID=3
BASIC_ID="gennai"
BASIC_PW="**********************"
HOST="***.***.***.***"
PORT="8000"

LOG_FILE=/tmp/plugin_test.log

Usage(){
    echo "Usage : $0  [print start datetime] [wav file]"
    echo "            print start datetime format : YYYYMMDD HH24:MI:SS"
    echo "            ex)"
    echo "            $0 \"20180728 19:10:15\" 3drecord.wav"
    exit 1
}

DATETIME=$1
AUDIO_FILE=$2
if [ $# != 2 ];then
    echo "Error : input param." | tee -a ${LOG_FILE}
    Usage
fi

file_nm=${AUDIO_FILE%.*}
extension=${AUDIO_FILE##*.}

if [ ${extension} != "wav" ]; then
    echo "Error : input param. Is not wav file." | tee -a ${LOG_FILE}
    Usage
fi

# convert
sox ${SCRIPT_DIR}/${AUDIO_FILE} ${SCRIPT_DIR}/${file_nm}.flac

rec_time=`sox ${SCRIPT_DIR}/${file_nm}.flac -n stats 2>&1 | grep Length | awk '{print $3}' | sed s/\.[0-9,]*$//g`
limit_cnt=$((${rec_time}/${distance}))

tmp_dir=${SCRIPT_DIR}/`date '+%s'`
if [ ! -d ${tmp_dir} ]; then
    mkdir ${tmp_dir}
fi

while [ $cnt -le ${limit_cnt} ]
do

    DATE_FORMAT=`echo ${DATETIME} | sed 's/"//g'`
    file=`date -d "${DATE_FORMAT} ${start} sec" "+%Y-%m-%dT%H%M%S000Z"`

    ### sox 2018_07_25-commu.flac output.wav trim ${start} ${end}
    echo "sox ${SCRIPT_DIR}/${file_nm}.flac ${tmp_dir}/${file}.${start}.${end}.flac trim ${start} ${distance}" | tee -a ${LOG_FILE}
    sox ${SCRIPT_DIR}/${file_nm}.flac ${tmp_dir}/${file}.${start}.${end}.flac trim ${start} ${distance}

    ### curl upload
    curl "http://${BASIC_ID}:${BASIC_PW}@${HOST}:${PORT}/upload" -X POST -F "file=@${tmp_dir}/${file}.${start}.${end}.flac" -F "printer_id=${PRINTER_ID}" -F "format=json"

    cnt=`expr ${cnt} + 1`
    start=${end}
    end=`expr ${end} + ${distance}`

    echo "$cnt:$start:$end:${file}"  | tee -a ${LOG_FILE}

done

# end
echo "cleaning files. ${tmp_dir} ${SCRIPT_DIR}/${file_nm}.flac ${SCRIPT_DIR}/${file_nm}.wav" | tee -a ${LOG_FILE}
rm -rf ${tmp_dir} ${SCRIPT_DIR}/${file_nm}.flac ${SCRIPT_DIR}/${file_nm}.wav
