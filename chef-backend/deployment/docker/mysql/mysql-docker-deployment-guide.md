# Docker MySQL 部署指南

## 🐳 快速部署

### 1. 启动MySQL容器
```bash
cd ~

mkdir ~/mysql/data ~/mysql/conf

vi ~/mysql/conf/my.cnf

vi ~/mysql/docker-compose.yml

docker compose up -d

# 查看容器状态
docker compose ps

# 查看MySQL日志
docker compose logs -f mysql
```

### 2. 验证MySQL连接
```bash
# 进入MySQL容器
docker exec -it mysql mysql -u chef_user -p

# 输入密码：ChefGameUser2025!@#
# 验证数据库和表
USE chef_game;
SHOW TABLES;
SELECT COUNT(*) FROM user;
```

### 3. 停止和清理
```bash
# 停止服务
docker compose down

# 删除数据卷（慎用！会删除所有数据）
docker compose down -v
```

## ⚙️ 配置说明

### Docker Compose 配置
- **容器名**: `chef-mysql`
- **端口映射**: `3306:3306`
- **数据持久化**: `/data/mysql` 目录
- **字符集**: `utf8mb4_unicode_ci`

### 数据库账户
- **Root密码**: `Root2025!@#`
- **应用用户**: `chef_user`
- **应用密码**: `ChefGameUser2025!@#`
- **数据库名**: `chef_game`

### 配置文件
- **MySQL配置**: `mysql/conf/my.cnf`
- **数据持久化**: `/data/mysql` 目录

## 🔧 自定义配置

### 修改密码
```yaml
# 修改 docker compose.yml
environment:
  MYSQL_ROOT_PASSWORD: 你的root密码
  MYSQL_PASSWORD: 你的应用密码
```

### 修改端口
```yaml
# 修改 docker compose.yml
ports:
  - "3307:3306"  # 宿主机端口:容器端口
```

### 数据备份
```bash
# 导出数据库
docker exec chef-mysql mysqldump -u chef_user -pChefGameUser2025!@# chef_game > backup.sql

# 导入数据库
docker exec -i chef-mysql mysql -u chef_user -pChefGameUser2025!@# chef_game < backup.sql
```

## ⚠️ 注意事项

1. **首次启动**需要等待MySQL初始化完成
2. **数据持久化**通过 `/data/mysql` 目录挂载，删除容器不会丢失数据
3. **数据库初始化**需要手动执行SQL脚本创建表结构
4. **生产环境**已使用安全密码配置
5. **防火墙**确保3306端口可访问
6. **时区设置**已配置为America/New_York