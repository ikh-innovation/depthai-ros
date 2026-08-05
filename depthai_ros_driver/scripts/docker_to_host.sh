#!/bin/bash

rosbag_folder=$1

SUB_DIR="/home/aristos/rosbags/$rosbag_folder"

# Copy from docker container to local host

echo "Copy to Host PC..."
    
HOST_USER="aristos"
HOST_IP="172.17.0.1" 
    
HOST_DEST="/home/${HOST_USER}/camera_rosbags/"

scp -r "$SUB_DIR" "${HOST_USER}@${HOST_IP}:${HOST_DEST}"

echo "good"