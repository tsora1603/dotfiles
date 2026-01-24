#!/bin/bash

# Check if gpu-screen-recorder is already running
if pgrep -f "gpu-screen-recorder" > /dev/null; then
    pkill -SIGINT -f gpu-screen-recorder
    notify-send '> Status' "Screen recording saved to $HOME/Videos/Recordings" -a 'Screen Recorder' -u low
else
    notify-send '> Status' 'Started screen recording' -a 'Screen Recorder' -u low
    gpu-screen-recorder \
        -w portal \
        -o ~/Videos/Recordings/screen_recording_$(date +%Y%m%d_%H%M%S).mp4 \
        -c mp4 \
        -a "default_output|default_input" \
        -k h264 \
	    -ac aac \
        -fm content \
	    -bm qp \
	    -cursor yes &
fi

