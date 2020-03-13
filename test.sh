#!/bin/sh
# MJR FILES 
MJR_VIDEO_FILE_1="$1/video-a.mjr"
MJR_AUDIO_FILE_1="$1/audio-a.mjr"
MJR_VIDEO_FILE_2="$1/video-b.mjr"
MJR_AUDIO_FILE_2="$1/audio-b.mjr"
# MEDIA FILES
MEDIA_VIDEO_FILE_1="$1/video-a.webm"
MEDIA_AUDIO_FILE_1="$1/audio-a.opus"
MEDIA_VIDEO_FILE_2="$1/video-b.webm"
MEDIA_AUDIO_FILE_2="$1/audio-b.opus"
# VIDEO FILES
MEDIA_VA_FILE_1="$1/a.mkv"
MEDIA_VA_FILE_2="$1/b.mkv"
# OUTPUT_FILE
OUTPUT_FILE="$1/ab.mkv"
janus-pp-rec $MJR_VIDEO_FILE_1 $MEDIA_VIDEO_FILE_1 -d 0
janus-pp-rec $MJR_AUDIO_FILE_1 $MEDIA_AUDIO_FILE_1 -d 0
janus-pp-rec $MJR_VIDEO_FILE_2 $MEDIA_VIDEO_FILE_2 -d 0
janus-pp-rec $MJR_AUDIO_FILE_2 $MEDIA_AUDIO_FILE_2 -d 0
ffmpeg -i $MEDIA_VIDEO_FILE_1 -i $MEDIA_AUDIO_FILE_1 -c copy $MEDIA_VA_FILE_1 -y -hide_banner -loglevel panic
ffmpeg -i $MEDIA_VIDEO_FILE_2 -i $MEDIA_AUDIO_FILE_2 -c copy $MEDIA_VA_FILE_2 -y -hide_banner -loglevel panic
ffmpeg -i $MEDIA_VA_FILE_1 -i $MEDIA_VA_FILE_2 -filter_complex "[0]pad=iw+5:color=black[left];[left][1]hstack=inputs=2" $OUTPUT_FILE -y -hide_banner -loglevel panic
