#!/bin/bash

# [cd到本脚本所在的目录，并获取本脚本所在目录的绝对路径]
# BASH_SOURCE[0]指运行改脚本的命令，如从op根目录下./tools/sim/start_openpilot_docker.sh运行该脚本，则BASH_SOURCE[0]的值即为./tools/sim/start_openpilot_docker.sh
# dirname "${BASH_SOURCE[0]}指获取文件路径，取出文件名，即为./tools/sim/
# /dev/null任何写到这里的内容都会被丢弃，经过测试这里是否重定向到/dev/null结果都一样
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
cd $DIR

# [为了在PC的显示器上显示docker内部的OP界面]
# Xserver提供界面显示，接受键盘鼠标等外设操作。这里指PC上运行的ubuntu20
# Xclient请求Xserver为其创建窗口绘制元素。这里指op container中的应用程序
# 而xhost就是Xserver的访问控制工具，控制那些Xclient能够在Xserver上显示，该命令必须从有显示的机器上运行
# expose X to the container
xhost +local:root

# [从远端拉去docker镜像，若远程更新，会增量式拉取新的layers]
docker pull ghcr.io/commaai/openpilot-sim:latest

# [设置默认OP路径为/openpilot]
OPENPILOT_DIR="/openpilot"
# [若设置了环境变量MOUNT_OPENPILOT，则执行接下来if内部的操作]
# -z(zero length)判断MOUNT_OPENPILOT变量是否为空，若为空则返回true
if ! [[ -z "$MOUNT_OPENPILOT" ]]
then
  # 向上返回两级目录，OPENPILOT_DIR为OP的根目录
  OPENPILOT_DIR="$(dirname $(dirname $DIR))"
  # -v(volume) 加载宿主机上的OP目录到docker容器中，容器中可以直接使用宿主机OP目录下的文件
  # -e(environmet) 设置容器中的PYTHONPATH环境变量，将宿主机的OP目录也加到容器的PYTHONPATH环境变量中
  EXTRA_ARGS="-v $OPENPILOT_DIR:$OPENPILOT_DIR -e PYTHONPATH=$OPENPILOT_DIR:$PYTHONPATH"
fi
# [默认使用docker container中/openpilot下的代码]
# [若执行该脚本之前'export MOUNT_OPENPILOT=1',则使用宿主机上该脚本所在的openpilot中的代码]

# [运行docker，并./tmux_script.sh运行脚本]
docker run --net=host\
  --name openpilot_client \
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
  /bin/bash -c "./tmux_script.sh $*"
