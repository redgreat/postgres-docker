#!/usr/bin/env bash
# docker build script

# 提前拉取镜像（反复打包测试时免除每次pull）
sudo docker pull postgres:16-alpine3.20

# 清理镜像
sudo docker rm postgres-docker
sudo docker rmi postgres-docker

# 打包
sudo docker build -t postgres-docker .

# 运行
# sudo docker run -itd --name postgres -p 5432:5432 -e POSTGRES_PASSWORD=xxx postgres-docker