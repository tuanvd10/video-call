#!/bin/bash

print_help()
{
    echo -e "\033[33mUsage: $1 [-d record_dir] [-t record_type] [-a1 audio1_mjr] [-v1 video1_mjr] [-a2 audio2_mjr] [-v2 video2_mjr] [-o output] [--help]\033[0m"
    echo "       -d: record dir (absolute path)"
    echo "       -t: record type (v: video; a: audio)"
    echo "       -a1: audio mjr file 1"
    echo "       -v1: video mjr file 1"
    echo "       -a2: audio mjr file 2"
    echo "       -v2: video mjr file 2"
    echo "       -o: output media file"
    echo "       -h: help"
    echo "       --help: help"
    echo ""
}

#-----------------------Start here------------------------
#echo "------------------"
echo -e "\033[1;34mTool     : Convert mjr to media file \033[0m"

#echo -e "\033[1mParsing... \033[0m"
for ((i=1; i<=$#; i++));
do
    if [ ${@:$i:1} = "-h" ];
    then
        print_help $0
        exit 1
    elif [ ${@:$i:1} = "--help" ];
    then
        print_help $0
        exit 1
    elif [ ${@:$i:1} = "-d" ];
    then
        DIR=${@:$((i+1)):1}
    elif [ ${@:$i:1} = "-t" ];
    then
        TYPE=${@:$((i+1)):1}
    elif [ ${@:$i:1} = "-a1" ];
    then
        AUDIO_MJR_FILE_1=${@:$((i+1)):1}
    elif [ ${@:$i:1} = "-v1" ];
    then
        VIDEO_MJR_FILE_1=${@:$((i+1)):1}
    elif [ ${@:$i:1} = "-a2" ];
    then
        AUDIO_MJR_FILE_2=${@:$((i+1)):1}
    elif [ ${@:$i:1} = "-v2" ];
    then
        VIDEO_MJR_FILE_2=${@:$((i+1)):1}
    elif [ ${@:$i:1} = "-o" ];
    then
        OUTPUT_NAME=${@:$((i+1)):1}
    fi
done

if [ -z ${DIR} ];
then
    echo -e "\033[31mThe dir is required\033[0m"
    print_help $0
    exit 1
fi
if [ ! -d ${DIR} ] 
then
    echo "The directory ${DIR} DOES NOT exists." 
    print_help $0
    exit 1
fi 

if [ -z ${TYPE} ];
then
    echo -e "\033[31mThe type is required\033[0m"
    print_help $0
    exit 1
fi
if [ "${TYPE}" != "v" ] && [ "${TYPE}" != "a" ];
then
    echo "Invalid record type" 
    print_help $0
    exit 1
fi 

#PROCESSING
if [ "${TYPE}" = "v" ]; then
    echo -e "\033[1mVideo converting... \033[0m"
	if [ ! -f "${DIR}/${AUDIO_MJR_FILE_1}" ] || [ ! -f "${DIR}/${AUDIO_MJR_FILE_2}" ] || [ ! -f "${DIR}/${VIDEO_MJR_FILE_1}" ] || [ ! -f "${DIR}/${VIDEO_MJR_FILE_2}" ]; 
	then
		echo "The MJR files (audio, video) is required"
		print_help $0
		exit 1
	fi	

	# MEDIA FILES
	VIDEO_MEDIA_FILE_1="${VIDEO_MJR_FILE_1}.webm"
	AUDIO_MEDIA_FILE_1="${AUDIO_MJR_FILE_1}.opus"
	VIDEO_MEDIA_FILE_2="${VIDEO_MJR_FILE_2}.webm"
	AUDIO_MEDIA_FILE_2="${AUDIO_MJR_FILE_2}.opus"
	# VIDEO FILES
	VA_MEDIA_FILE_1="${VIDEO_MJR_FILE_1}-${AUDIO_MJR_FILE_1}.webm"
	VA_MEDIA_FILE_2="${VIDEO_MJR_FILE_2}-${AUDIO_MJR_FILE_2}.webm"

	# OUTPUT_FILE
	OUTPUT_FILE="${OUTPUT_NAME}.webm"
    
	# PROCESS
	janus-pp-rec "${DIR}/${VIDEO_MJR_FILE_1}" "${DIR}/${VIDEO_MEDIA_FILE_1}" -d 0
	janus-pp-rec "${DIR}/${AUDIO_MJR_FILE_1}" "${DIR}/${AUDIO_MEDIA_FILE_1}" -d 0
	janus-pp-rec "${DIR}/${VIDEO_MJR_FILE_2}" "${DIR}/${VIDEO_MEDIA_FILE_2}" -d 0
	janus-pp-rec "${DIR}/${AUDIO_MJR_FILE_2}" "${DIR}/${AUDIO_MEDIA_FILE_2}" -d 0
	ffmpeg -i "${DIR}/${VIDEO_MEDIA_FILE_1}" -i "${DIR}/${AUDIO_MEDIA_FILE_1}" -c copy "${DIR}/${VA_MEDIA_FILE_1}" -y -hide_banner -loglevel panic
	ffmpeg -i "${DIR}/${VIDEO_MEDIA_FILE_2}" -i "${DIR}/${AUDIO_MEDIA_FILE_2}" -c copy "${DIR}/${VA_MEDIA_FILE_2}" -y -hide_banner -loglevel panic
	ffmpeg -i "${DIR}/${VA_MEDIA_FILE_1}" -i "${DIR}/${VA_MEDIA_FILE_2}" -filter_complex "[0]pad=iw+5:color=black[left];[left][1]hstack=inputs=2" "$DIR/${OUTPUT_FILE}" -y -hide_banner -loglevel panic
	# remove unused files
	rm "${DIR}/${VIDEO_MJR_FILE_1}" "${DIR}/${VIDEO_MEDIA_FILE_1}" "${DIR}/${AUDIO_MJR_FILE_1}" "${DIR}/${AUDIO_MEDIA_FILE_1}" "${DIR}/${VIDEO_MJR_FILE_2}" "${DIR}/${VIDEO_MEDIA_FILE_2}" "${DIR}/${AUDIO_MJR_FILE_2}" "${DIR}/${AUDIO_MEDIA_FILE_2}" "${DIR}/${VA_MEDIA_FILE_1}" "${DIR}/${VA_MEDIA_FILE_2}"   
#	echo -e "\033[Finished... \033[0m"
fi 

if [ "${TYPE}" = "a" ]; then
    echo -e "\033[1mAudio converting... \033[0m"
	if [ ! -f "${DIR}/${AUDIO_MJR_FILE_1}" ] || [ ! -f "${DIR}/${AUDIO_MJR_FILE_2}" ]; 
	then
		echo "The MJR files (audio) is required"
		print_help $0
		exit 1
	fi	

	# MEDIA FILES
	AUDIO_MEDIA_FILE_1="${AUDIO_MJR_FILE_1}.opus"
	AUDIO_MEDIA_FILE_2="${AUDIO_MJR_FILE_2}.opus"
	# OUTPUT_FILE
	OUTPUT_FILE="${OUTPUT_NAME}.mp3"
    
	# PROCESS
	janus-pp-rec "${DIR}/${AUDIO_MJR_FILE_1}" "${DIR}/${AUDIO_MEDIA_FILE_1}" -d 0
	janus-pp-rec "${DIR}/${AUDIO_MJR_FILE_2}" "${DIR}/${AUDIO_MEDIA_FILE_2}" -d 0
	ffmpeg -i "${DIR}/${AUDIO_MEDIA_FILE_1}"  -i "${DIR}/${AUDIO_MEDIA_FILE_2}" -filter_complex amerge "${DIR}/${OUTPUT_FILE}" -y -hide_banner -loglevel panic
	# remove unused files
	rm "${DIR}/${AUDIO_MJR_FILE_1}" "${DIR}/${AUDIO_MEDIA_FILE_1}" "${DIR}/${AUDIO_MJR_FILE_2}" "${DIR}/${AUDIO_MEDIA_FILE_2}"   
#	echo -e "\033[Finished... \033[0m"
fi 






