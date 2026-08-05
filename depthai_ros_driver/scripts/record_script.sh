#!/bin/bash

show_help()
{
   # Display Help
   echo
   echo "A simple bash script for recording rosbags for the OAK-D Pro W Stereo Camera."
   echo "Launch Parameters are saved in the same folder as the rosbag in a YAML file."
   echo "Proper naming for both the folder, the bag and the yaml file are ensured."
   echo "Aguments:"
   echo "1) Topics to record:"
   echo "       - 1 for rgb, stereo, left/right and PCL (stereo and LiDAR) topics."
   echo "       - 2 for rgb and stereo topics only."
   echo "       - 3 for rgb, stereo, left/right topics only."
   echo "2) Test number for folder and files name."
   echo "3) Whether to copy the rosbag from the docker container to local host PC."
   echo
}

# Show help if chosen
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Input Arguments
TOPIC_CHOICE=$1
TEST_NUM=$2
COPY_TO_HOST=$3

# record params 
split_size=2048
buff_size=2048
chunk_size=10240

dt=$(date '+%Y_%m_%d_%H-%M-%S');

# Configure base and subfolder paths
BASE_DIR="/home/aristos/catkin_ws/src/depthai-ros/depthai_ros_driver/rosbag_records"
if [ -z "$TEST_NUM" ]; then
    FOLDER_NAME="rosbag_test_${TEST_NUM}_${dt}"
else
    FOLDER_NAME="rosbag_test_${TEST_NUM}_${dt}"
fi
SUB_DIR="${BASE_DIR}/${FOLDER_NAME}"
mkdir -p "$SUB_DIR"

# Choose topics to record
case "$TOPIC_CHOICE" in
    1)
        TOPICS_TO_RECORD="/oak/rgb/camera_info
                          /oak/rgb/image_raw/compressed 
                          /oak/stereo/camera_info
                          /oak/stereo/image_raw 
                          /oak/right/camera_info
                          /oak/right/image_raw/compressed 
                          /oak/left/camera_info
                          /oak/left/image_raw/compressed    
                          /oak/points 
                          /aristos/livox/lidar
                          /aristos/ekf/global/pose_estimation"
        ;;
    2)
        TOPICS_TO_RECORD="/oak/rgb/camera_info 
                          /oak/rgb/image_raw/compressed 
                          /oak/stereo/camera_info
                          /oak/stereo/image_raw
                          /aristos/ekf/global/pose_estimation"
        ;;
    3)
        TOPICS_TO_RECORD="/oak/rgb/camera_info
                          /oak/rgb/image_raw/compressed 
                          /oak/stereo/camera_info
                          /oak/stereo/image_raw 
                          /oak/right/camera_info
                          /oak/right/image_raw/compressed 
                          /oak/left/camera_info
                          /oak/left/image_raw/compressed
                          /aristos/ekf/global/pose_estimation"
        ;;
    *)
        echo "Only 1, 2, 3 are valid options"
        exit 1
        ;;
esac

# Save launch params
echo "Saving Launch file params ..."
if [ -z "$TEST_NUM" ]; then
    YAML_FILE="${SUB_DIR}/oak_parameters_${dt}.yaml"
else
    YAML_FILE="${SUB_DIR}/oak_parameters_test_${TEST_NUM}_${dt}.yaml"
fi
rosparam dump "$YAML_FILE" /oak

echo "Will record topics: $TOPICS_TO_RECORD"  

# Rosbag record
if [ -z "$TEST_NUM" ]; then
    BAG_FILE="${SUB_DIR}/oak_recording_test_${TEST_NUM}"
else
    BAG_FILE="${SUB_DIR}/oak_recording_test_${TEST_NUM}_${dt}"
fi

echo "Start recording ..."
rosbag record --split --size=$split_size -b $buff_size --chunksize=$chunk_size --lz4 $TOPICS_TO_RECORD -O $BAG_FILE

echo "Shutdown ..."

# Copy from docker container to local host
if [[ "$COPY_TO_HOST" == "1" ]]; then
    echo "Copy to Host PC..."
    
    HOST_USER="aristos"
    HOST_IP="172.17.0.1" 
    
    HOST_DEST="/home/${HOST_USER}/camera_rosbags/"
    
    scp -r "$SUB_DIR" "${HOST_USER}@${HOST_IP}:${HOST_DEST}"

    echo "good"
fi