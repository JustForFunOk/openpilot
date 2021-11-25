#!/bin/bash
# 启动openpilot_docker后会执行该脚本
# tmux能将终端窗口(terminal window)和会话(session)解帮，用于一次连接docker中执行多个脚本
# 网络上现有的tmux命令都不全面，直接安装tmux并进入tmux中通过tab查看详细命令

# 新建一个名为carla-sim的session(-s)，并与窗口解绑(-d detach)
tmux new -d -s carla-sim

# 执行该脚本，等效于人工敲ENTER键(send-keys)执行
tmux send-keys "./launch_openpilot.sh" ENTER

# 创建一个新的窗口(new window)
tmux neww

# 执行该脚本，同上
tmux send-keys "./bridge.py $*" ENTER

# 将当前窗口绑定到名为carla-sim的session上
tmux a -t carla-sim

# [至此新建了一个名为carla-sim的session，并有两个窗口，每个窗口上执行了一个脚本]