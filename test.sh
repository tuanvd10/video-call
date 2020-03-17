#!/bin/sh
# PARAMETERS
DIR=$1
P1=$2
P2=$3

# MJR FILES 
MJR_VIDEO_FILE_1="${DIR}/${P1}_video.mjr"
MJR_AUDIO_FILE_1="${DIR}/${P1}_audio.mjr"
MJR_VIDEO_FILE_2="${DIR}/${P2}_video.mjr"
MJR_AUDIO_FILE_2="${DIR}/${P2}_audio.mjr"
# MEDIA FILES
MEDIA_VIDEO_FILE_1="${DIR}/video-a.webm"
MEDIA_AUDIO_FILE_1="${DIR}/audio-a.opus"
MEDIA_VIDEO_FILE_2="${DIR}/video-b.webm"
MEDIA_AUDIO_FILE_2="${DIR}/audio-b.opus"
# VIDEO FILES
MEDIA_VA_FILE_1="${DIR}/a.mkv"
MEDIA_VA_FILE_2="${DIR}/b.mkv"
# OUTPUT_FILE
OUTPUT_FILE="${DIR}/videocall_${P1}-${P2}.mkv"

# PROCESSING
echo "Start converting to video file: ${P1}-${P2}"
echo $MJR_VIDEO_FILE_1
echo $MJR_AUDIO_FILE_1
janus-pp-rec $MJR_VIDEO_FILE_1 $MEDIA_VIDEO_FILE_1 -d 0
janus-pp-rec $MJR_AUDIO_FILE_1 $MEDIA_AUDIO_FILE_1 -d 0
janus-pp-rec $MJR_VIDEO_FILE_2 $MEDIA_VIDEO_FILE_2 -d 0
janus-pp-rec $MJR_AUDIO_FILE_2 $MEDIA_AUDIO_FILE_2 -d 0
ffmpeg -i $MEDIA_VIDEO_FILE_1 -i $MEDIA_AUDIO_FILE_1 -c copy $MEDIA_VA_FILE_1 -y -hide_banner -loglevel panic
ffmpeg -i $MEDIA_VIDEO_FILE_2 -i $MEDIA_AUDIO_FILE_2 -c copy $MEDIA_VA_FILE_2 -y -hide_banner -loglevel panic
ffmpeg -i $MEDIA_VA_FILE_1 -i $MEDIA_VA_FILE_2 -filter_complex "[0]pad=iw+5:color=black[left];[left][1]hstack=inputs=2" $OUTPUT_FILE -y -hide_banner -loglevel panic

# remove unused files
rm $MJR_VIDEO_FILE_1 $MJR_AUDIO_FILE_1 $MJR_VIDEO_FILE_2 $MJR_AUDIO_FILE_2 $MEDIA_VIDEO_FILE_1 $MEDIA_AUDIO_FILE_1 $MEDIA_VIDEO_FILE_2 $MEDIA_AUDIO_FILE_2 $MEDIA_VA_FILE_1 $MEDIA_VA_FILE_2
