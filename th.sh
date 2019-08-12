#!/bin/bash
# 
#
# Dependencies:
# 1. ffmpeg
# 2. ImageMagick
#
# Usage:
# ./th.sh NFRAMES TILE SIZE INPUT
#
# NFRAMES is the number of frames (thumbnails) to generate, e.g., 16;
# TILE is in the form "MxN" (where M * N should match NFRAMES), e.g., 4x4;
# SIZE is the length of the longer side of the output, e.g., 1920 if you want
# to get an 1920*1080 output image;
# INPUT is the path to the input file;
# OUTPUT is the path to the output file (make sure intermediate directories
# exist).
#
# Example:
# ./thumbnails.sh 16 4x4 1920 video.mp4 thumbnails.png
#
# Credit:
# http://goo.gl/vzXW1b (FFmpeg wiki: generate thumbnails)
# http://stackoverflow.com/q/7395343 (extract video length)
# http://apple.stackexchange.com/q/52879 (combine images)

if [[ $# != 4 ]]; then
    echo "wrong number of arguments

Usage:
./thumbnails.sh NFRAMES TILE SIZE INPUT

NFRAMES is the number of frames (thumbnails) to generate, e.g., 16;
TILE is in the form 'MxN' (where M * N should match NFRAMES), e.g., 4x4;
SIZE is the length of the longer side of the output, e.g., 1920 if you want
to get an 1920*1080 output image;
INPUT is the path to the input file;
OUTPUT is the path to the output file (make sure intermediate directories
exist).

Example:
./th.sh 16 4x4 1920 video.mp4
"
    return 1
fi
#ffmpeg -start_at_zero -copyts -ss 00:00:14 -i Rammstein\ -\ Radio.mp4 -vf "drawtext=fontfile=/path/to/Arial.ttf:fontsize=45:fontcolor=yellow:box=1:boxcolor=black:x=(W-tw)/2:y=H-th-10:text='%{pts\:gmtime\:0\:%H\\\\\\:%M\\\\\:%S}'" -vframes 1 output.png

NFRAMES=$1
TILE=$2
SIZE=$3
INPUT=$4

#DURATION=$(ffprobe -loglevel error -show_streams "$4" | grep duration= | cut -f2 -d= | head -1)
DURX=$(ffmpeg -i "$4" 2>&1 | grep Duration | awk '{print $2}' | tr -d ,)
DURATION=$(ffmpeg -i "$4" 2>&1 | grep "Duration"| cut -d ' ' -f 4 | sed s/,// | sed 's@\..*@@g' | awk '{ split($1, A, ":"); split(A[3], B, "."); print 3600*A[1] + 60*A[2] + B[1] }')
RES=$(ffmpeg -i "$4" 2>&1 | grep -oP 'Stream .*, \K[0-9]+x[0-9]+')
FILESIZE=$(du -sm "$4" | awk '{print $1}')
# generate thumbnails in the /tmp folder
TMPDIR=/tmp/thumbnails-${RANDOM}/
mkdir $TMPDIR
#filame

for (( VARIABLE=0; VARIABLE<NFRAMES; VARIABLE++ ))
do
OFFSET=$(echo "scale=2;$VARIABLE*$DURATION/$NFRAMES+$DURATION/$NFRAMES/2" | bc)

if [ $VARIABLE -gt 9 ];then
  ZEROS="00"
  if [ $VARIABLE -gt 99 ];then
    ZEROS="0"
    if  [ $VARIABLE -gt 999 ];then
       ZEROS=""
    fi
  fi
else
  ZEROS="000"
fi

#ffmpeg -start_at_zero -copyts -ss $OFFSET -i "$4" -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:fontsize=45:fontcolor=yellow:box=1:boxcolor=black:x=(W-tw)/2:y=H-th-10:text='%{pts\:gmtime\:0\:%H\\\\\\:%M\\\\\:%S}'" -vframes 1 ${TMPDIR}$ZEROS$VARIABLE.jpg
ffmpeg -start_at_zero -copyts -ss $OFFSET -i "$4" -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:fontsize=45:fontcolor=white::shadowcolor=black:shadowx=2:shadowy=2:box=1:boxcolor=black@0:x=(W-tw)/40:y=H-th-10:text='%{pts\:gmtime\:0\:%H\\\\\\:%M\\\\\:%S}'" -vframes 1 ${TMPDIR}$ZEROS$VARIABLE.jpg
done
montage ${TMPDIR}*.jpg -background white -geometry +5+5 -tile $TILE ${TMPDIR}output.jpg
echo $4 >>${TMPDIR}myfile.txt
echo $RES >>${TMPDIR}myfile.txt
echo "$FILESIZE Mb" >>${TMPDIR}myfile.txt
echo $DURX >>${TMPDIR}myfile.txt

convert -size ${SIZE}x150 -fill black -interline-spacing 10 -background white -pointsize 20 -gravity west caption:@${TMPDIR}myfile.txt ${TMPDIR}text1.jpg


convert ${TMPDIR}output.jpg -resize ${SIZE}x${SIZE} ${TMPDIR}th.jpg
thewidth=$(identify -ping -format %w ${TMPDIR}th.jpg)
convert ${TMPDIR}text1.jpg -crop ${thewidth}x150+0+0 ${TMPDIR}text.jpg


montage ${TMPDIR}text.jpg ${TMPDIR}th.jpg -background white -geometry +0+0 -tile 1x2 thumbnails-${RANDOM}.jpg
