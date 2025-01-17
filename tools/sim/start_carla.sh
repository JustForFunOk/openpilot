#!/bin/bash

# Requires nvidia docker - https://github.com/NVIDIA/nvidia-docker
if ! $(apt list --installed | grep -q nvidia-container-toolkit); then
  if [ -z "$INSTALL" ]; then
    echo "Nvidia docker is required. Re-run with INSTALL=1 to automatically install."
    exit 0
  else
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    echo $distribution
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
    sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
    sudo systemctl restart docker
  fi
fi

docker pull carlasim/carla:0.9.12

# 启动Carla
# -opengl carla0.9.12开始就不支持opengl了，这个为啥没去掉？
# -nosound
# -RenderOffScreen 除了不显示画面，均在正常工作
# -benchmark 保留所有的Frame，不跳过
# -fps=20
# -quality-level=High 渲染的质量等级，有Low，Epic，降低质量以减轻GPU负担
docker run \
  --rm \
  --gpus all \
  --net=host \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -it \
  carlasim/carla:0.9.12 \
  /bin/bash ./CarlaUE4.sh -opengl -nosound -RenderOffScreen -benchmark -fps=20 -quality-level=High
