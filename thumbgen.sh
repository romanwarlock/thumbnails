#!/bin/bash
# 
# Dependencies/Requirements:
# 1. ffmpeg 
# 2. awk
# 3. sed
# 4. linux commands
# bc dependence has been REMOVED - awk is used for calculations
# ImageMagick dependence has been REMOVED - ffmpeg is used to work with jpg-files
# 
# Usage:
# . thumbgen.sh COLUMNS ROWS SIZE INPUT
#
# COLUMNS means number of columns;
# ROWS means number of rows;
# SIZE is the length of the longer side of the output, e.g., 1920 if you want
# to get an 1920x1080 output image;
# INPUT is the path to the input file;
#
# Example:
# . thumbgen.sh 3 14 1920 video.mp4
# . <path-to-file>/thumbgen.sh 3 14 1920 video.mp4
#
#if $ffmpeg  is not installed via snap / apt-get / etc.../ I just downloaded already compiled:
# $ffmpeg  can be set as $ffmpeg ="/media/rk/0/soft/$ffmpeg -4.4-amd64-static/$ffmpeg " and further
#the command "$ffmpeg " shall be replaced with the variable "$ffmpeg "
#
#if path to file or filename has special characters (space, etc) use "":
# . thumbgen.sh 3 14 1920 "/wh ateve R/v (i) {deo.mp4"


if [[ $# != 4 ]]; then
    echo "wrong number of arguments

Usage:
. thumbgen.sh COLUMNS ROWS SIZE INPUT
COLUMNS means number of columns;TILE is in the form 'MxN' (where M * N should match NFRAMES), e.g., 4x4;
ROWS means nubler of rows;
SIZE is the length of the longer side of the output, e.g., 1920 if you want
to get an 1920*1080 output image;
INPUT is the path to the input file;
OUTPUT is the path to the output file (make sure intermediate directories
exist).

Example:
. th.sh 3 14 1920 video.mp4
"
    return 1
fi

#------------- d e f i n e   f f m p e g   a n d   f o n t   n a m e   a n d   s i z e
ffmpeg="ffmpeg"
font="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
font="/usr/share/fonts/truetype/ubuntu/UbuntuMono-R.ttf"
fontsize=120

#----- d e f i n e   t e m p o r a r y   s t o r a g e   a n d   c r e a t e   i f   n e e d e d
TMPDIR=/mnt/c/Users/roman/Downloads/
#TMPDIR=/tmp/thumbnails-${RANDOM}/
#mkdir $TMPDIR
TMPDIR=/mnt/c/Users/roman/Downloads/

X=$1
Y=$2
NFRAMES=`echo | awk '{print (X*Y)}' X="$X" Y="$Y}}"`
TILE=$(echo "${X}x${Y}")
SIZE=$3
INPUT=$4

DURX=$($ffmpeg  -i "$4" 2>&1 | grep Duration | awk '{print $2}' | tr -d ,)
DURATION=$($ffmpeg  -i "$4" 2>&1 | grep "Duration"| cut -d ' ' -f 4 | sed s/,// | sed 's@\..*@@g' | awk '{ split($1, A, ":"); split(A[3], B, "."); print 3600*A[1] + 60*A[2] + B[1] }')
RES=$($ffmpeg  -i "$4" 2>&1 | grep -oP 'Stream .*, \K[0-9]+x[0-9]+')
FILESIZE=$(du -sm "$4" | awk '{print $1}')
echo "  $4" >>${TMPDIR}myfile.txt
echo "  $RES" >>${TMPDIR}myfile.txt
echo "  $FILESIZE Mb" >>${TMPDIR}myfile.txt
echo "  $DURX" >>${TMPDIR}myfile.txt



for (( VARIABLE=0; VARIABLE<NFRAMES; VARIABLE++ ))
do
OFFSET=`echo "input data" | awk '{print (VARIABLE*DURATION/NFRAMES+DURATION/NFRAMES/2)}' DURATION="${DURATION}}" NFRAMES="${NFRAMES}}" VARIABLE="${VARIABLE}"`

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
$ffmpeg  -start_at_zero -copyts -ss $OFFSET -i "$4" -vf "drawtext=fontfile=$font:fontsize=${fontsize}:fontcolor=white::shadowcolor=black:shadowx=2:shadowy=2:box=1:boxcolor=black@0:x=(W-tw)/40:y=H-th-10:text='%{pts\:gmtime\:0\:%H\\\\\\:%M\\\\\:%S}'" -vframes 1 ${TMPDIR}$ZEROS$VARIABLE.jpeg
done
$ffmpeg  -pattern_type glob -i "${TMPDIR}*.jpeg" -filter_complex tile=$TILE:margin=4:padding=4:color=white ${TMPDIR}output.jpeg

thewidth=$($ffmpeg  -i ${TMPDIR}output.jpeg 2>&1 |grep Video|awk '{ split( $8, pieces,  /[x,]/ ) ; print pieces[1] }')

theheight=$($ffmpeg  -i ${TMPDIR}output.jpeg 2>&1 |grep Video|awk '{ split( $8, pieces,  /[x,]/ ) ; print pieces[2] }')

theheight=`echo | awk '{printf  "%.0f ", theheight*SIZE/thewidth}' theheight="${theheight}" SIZE="${SIZE}" thewidth="${thewidth}"`

$ffmpeg  -i ${TMPDIR}output.jpeg -vf scale=${SIZE}x${theheight} -vframes 1 ${TMPDIR}th.jpeg
theheight=`echo | awk '{printf  "%.0f ", 150+theheight}' theheight="${theheight}}"`

$ffmpeg  -f lavfi -i color=white:${SIZE}x${theheight} -i ${TMPDIR}th.jpeg -filter_complex "[0:v][1:v] overlay=0:150,drawtext=fontfile=${font}:fontsize=20:fontcolor=black:x=30:y=20:textfile=${TMPDIR}myfile.txt" -vframes 1 th${RANDOM}.jpg
