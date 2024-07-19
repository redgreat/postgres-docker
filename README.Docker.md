# postgres + 指定插件

项目介绍
---

postgres官方基础镜像

 - postgres: 16-alpine3.20 
 - postgis: 3.4.2
 - pg_stat_monitor: 2.0.4
 - pg_cron: 1.6.2
 - pg_uuidv7: 1.5.0

---

## 打包&&运行
```shell
# 提前拉取镜像（反复打包测试时免除每次pull）
sudo docker pull postgres:16-alpine3.20

# 清理镜像
sudo docker rm postgres-docker
sudo docker rmi postgres-docker

# 打包
sudo docker build -t postgres-docker .

# 运行
sudo docker run -itd --name postgres -p 5432:5432 -e POSTGRES_PASSWORD=xxx postgres-docker
```
