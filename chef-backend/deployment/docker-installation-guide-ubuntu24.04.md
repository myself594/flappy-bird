# Docker 安装指南 - Ubuntu 24.04.3 LTS

## 📋 系统要求

- Ubuntu 24.04.3 LTS (Kernel 5.15+)
- 64位操作系统
- 至少2GB可用内存
- sudo权限

## 🐳 Docker Engine 安装

### 1. 更新系统包
```bash
# 更新包索引
sudo apt update

# 升级系统包
sudo apt upgrade -y
```

### 2. 安装必要的依赖包
```bash
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https
```

### 3. 添加Docker官方GPG密钥
```bash
# 创建apt密钥目录
sudo mkdir -m 0755 -p /etc/apt/keyrings

# 下载并添加Docker GPG密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 设置正确的权限
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

### 4. 添加Docker APT仓库
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 5. 安装Docker Engine
```bash
# 更新包索引
sudo apt update

# 安装Docker Engine, CLI和containerd
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

# 验证安装
sudo docker --version
```

## 🔧 Docker Compose 安装

### 方法一：使用官方二进制文件（推荐）
```bash
# 下载最新版本的Docker Compose
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')

sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose

# 设置执行权限
sudo chmod +x /usr/local/bin/docker-compose

# 创建软链接（可选）
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# 验证安装
docker-compose --version
```

### 方法二：使用Docker插件（新版本）
```bash
# Docker Compose作为Docker插件已自动安装
# 使用 'docker compose' 命令（注意空格）
docker compose version
```

## 🚀 配置开机自启动

### 1. 启用Docker服务
```bash
# 启动Docker服务
sudo systemctl start docker

# 设置开机自启动
sudo systemctl enable docker

# 检查服务状态
sudo systemctl status docker
```

### 2. 启用containerd服务
```bash
# 启动containerd服务
sudo systemctl start containerd

# 设置开机自启动
sudo systemctl enable containerd

# 检查服务状态
sudo systemctl status containerd
```

## 👥 用户权限配置

### 1. 添加用户到docker组
```bash
# 将当前用户添加到docker组
sudo usermod -aG docker $USER

# 或者指定用户名
sudo usermod -aG docker 用户名
```

### 2. 重新登录或刷新权限
```bash
# 方法一：重新登录系统
# logout 然后重新登录

# 方法二：刷新用户组权限
newgrp docker

# 方法三：重启系统
sudo reboot
```

## ✅ 验证安装

### 1. 测试Docker
```bash
# 运行hello-world容器
docker run hello-world

# 查看Docker信息
docker info

# 查看Docker版本
docker --version
```

### 2. 测试Docker Compose
```bash
# 检查Docker Compose版本
docker-compose --version
# 或者新语法
docker compose version
```

### 3. 测试权限
```bash
# 不使用sudo运行Docker命令
docker ps
docker images
```

## 🛠️ 常见问题排查

### 问题1：权限被拒绝
```bash
# 错误：permission denied while trying to connect to Docker daemon
# 解决：确保用户在docker组中
groups $USER
sudo usermod -aG docker $USER
newgrp docker
```

### 问题2：Docker服务未启动
```bash
# 检查服务状态
sudo systemctl status docker

# 启动服务
sudo systemctl start docker

# 查看日志
sudo journalctl -u docker.service
```

### 问题3：GPG密钥错误
```bash
# 重新添加GPG密钥
sudo rm -f /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

## 📦 卸载Docker（如需要）

### 1. 卸载Docker包
```bash
sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
```

### 2. 清理残留文件
```bash
# 删除Docker数据目录
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# 删除配置文件
sudo rm -rf /etc/docker

# 删除GPG密钥和仓库文件
sudo rm -f /etc/apt/keyrings/docker.gpg
sudo rm -f /etc/apt/sources.list.d/docker.list
```

## 🔧 Docker配置优化

### 1. 配置Docker守护程序
```bash
# 创建Docker配置目录
sudo mkdir -p /etc/docker

# 创建daemon.json配置文件
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# 重启Docker服务
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 2. 配置日志轮转
```bash
# Docker日志会自动轮转，也可以配置logrotate
sudo tee /etc/logrotate.d/docker > /dev/null <<EOF
/var/lib/docker/containers/*/*.log {
  rotate 7
  daily
  compress
  size 10M
  missingok
  delaycompress
  copytruncate
}
EOF
```

## 📊 系统资源监控

### 1. 查看Docker资源使用
```bash
# 查看Docker系统信息
docker system df

# 查看容器资源使用
docker stats

# 清理未使用的资源
docker system prune -a
```

### 2. 查看服务状态
```bash
# 查看Docker服务状态
sudo systemctl is-active docker
sudo systemctl is-enabled docker

# 查看开机启动项
systemctl list-unit-files --type=service | grep docker
```

## 🎯 安装验证清单

安装完成后，请验证以下项目：

- [ ] `docker --version` 显示版本信息
- [ ] `docker-compose --version` 显示版本信息  
- [ ] `docker run hello-world` 成功运行
- [ ] `docker ps` 不需要sudo权限
- [ ] `sudo systemctl status docker` 显示active状态
- [ ] 重启系统后Docker服务自动启动

## 🚀 下一步

安装完成后，可以：
1. 部署chef-backend项目的MySQL服务
2. 学习Docker Compose编排多容器应用
3. 配置Docker容器监控和日志

---

**安装完成！** 🎉

现在可以返回项目根目录，使用以下命令启动MySQL服务：

```bash
cd chef-backend
docker compose up -d mysql
```