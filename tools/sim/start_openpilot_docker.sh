#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
cd $DIR

# expose X to the container
xhost +local:root

# 'docker pull' cost too much time, and we don't need latest version every time
# docker pull ghcr.io/commaai/openpilot-sim:latest

# execute openpilot built in host machine , not in docker container
export MOUNT_OPENPILOT=1
OPENPILOT_DIR="/openpilot"
if ! [[ -z "$MOUNT_OPENPILOT" ]]
then
  OPENPILOT_DIR="$(dirname $(dirname $DIR))"
  EXTRA_ARGS="-v $OPENPILOT_DIR:$OPENPILOT_DIR -e PYTHONPATH=$OPENPILOT_DIR:$PYTHONPATH"
fi

CONTAINER_NAME="openpilot_client"

# open an independent terminal for ./bridge.py
gnome-terminal --title="bridge" \
  -- /bin/bash -c " \
docker run --net=host\
  --name $CONTAINER_NAME \
  --rm \
  -it \
  --gpus all \
  --device=/dev/dri:/dev/dri \
  --device=/dev/input:/dev/input \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  --shm-size 1G \
  -e DISPLAY=$DISPLAY \
  -e QT_X11_NO_MITSHM=1 \
  -w "$OPENPILOT_DIR/tools/sim" \
  $EXTRA_ARGS \
  ghcr.io/commaai/openpilot-sim:latest \
  /bin/bash -c "./video_bridge.py $*" \
  "

sleep 0.1 # sleep 0.1 second, wait for container is running

docker exec -it $CONTAINER_NAME \
  /bin/bash -c "./launch_openpilot.sh"
